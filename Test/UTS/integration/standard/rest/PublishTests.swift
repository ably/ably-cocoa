import Testing
import Foundation
import Ably

/// REST channel publish (RSL1d, RSL1n, RSL1k5, RSL1l1, RSL1m4)
/// Derived from ably/specification `uts/rest/integration/publish.md`
///
/// Direct-sandbox integration test against the Ably Sandbox (`sandbox.realtime.ably-nonprod.net`,
/// via SandboxApp.sandboxHost) — no proxy, no fault injection. Provisions a throwaway SandboxApp
/// and points real REST clients straight at the sandbox. Needs outbound network:
///
/// ```bash
/// swift test --filter UTS.PublishTests
/// ```
@Suite(.serialized)
final class PublishTests: IntegrationTestCase {

    // UTS: rest/integration/RSL1d/publish-failure-error-0
    @Test(arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func test_RSL1d_error_indication_on_publish_failure(useBinaryProtocol: Bool) async throws {
        // The spec's BEFORE/AFTER ALL sandbox app provisioning is owned by the withSandboxApp scope.
        try await withSandboxApp { app in
            // Setup
            let channelName = "forbidden-channel-\(UUID().uuidString)" // Not in restricted key's capability

            // restricted_key = app_config.keys[2]  # per-channel capabilities
            try #require(app.keys.count > 2, "test-app-setup.json should provision keys[2] (per-channel capabilities)")
            // Key without publish capability for this channel
            let restrictedKey = app.keys[2]

            let restrictedOptions = ARTClientOptions(key: restrictedKey)
            restrictedOptions.restHost = SandboxApp.sandboxHost // the spec's endpoint: "nonprod:sandbox"
            restrictedOptions.useBinaryProtocol = useBinaryProtocol
            let restrictedClient = ARTRest(options: restrictedOptions)
            let restrictedChannel = restrictedClient.channels.get(channelName)

            // Test Steps
            // AWAIT restricted_channel.publish(name: "event", data: "data") FAILS WITH error
            let error = try #require(await self.publishError(restrictedChannel, name: "event", data: "data"))
            #expect(error.code == 40160) // Not permitted
            #expect(error.statusCode == 401)
        }
    }

    // UTS: rest/integration/RSL1n/publish-result-serials-0
    @Test(arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func test_RSL1n_publish_result_contains_serials(useBinaryProtocol: Bool) async throws {
        try await withSandboxApp { app in
            // Setup
            let options = ARTClientOptions(key: app.defaultKey)
            options.restHost = SandboxApp.sandboxHost // the spec's endpoint: "nonprod:sandbox"
            options.useBinaryProtocol = useBinaryProtocol
            let client = ARTRest(options: options)
            let channelName = "test-serials-\(UUID().uuidString)"
            let channel = client.channels.get(channelName)

            // Test Steps
            // Single message
            let result1 = try #require(await self.publishResult(channel, name: "event1", data: "data1"))

            // ASSERT result1.serials IS List
            // (no separate assertion: satisfied by the type system — ARTPublishResult.serials is
            // [ARTPublishResultSerial])
            #expect(result1.serials.count == 1)
            // ASSERT result1.serials[0] IS String — cocoa wraps each serial in an
            // ARTPublishResultSerial; the string is its `value` (nil only when the message was
            // discarded by a conflation rule), so require it to be present.
            let serial1 = try #require(result1.serials[0].value)
            #expect(serial1.count > 0)

            // Multiple messages
            let result2 = try #require(await self.publishResult(channel, messages: [
                ARTMessage(name: "event2", data: "data2"),
                ARTMessage(name: "event3", data: "data3"),
                ARTMessage(name: "event4", data: "data4"),
            ]))

            #expect(result2.serials.count == 3)
            // ASSERT ALL serial IN result2.serials: serial IS String AND serial.length > 0
            let serialValues = result2.serials.compactMap(\.value)
            #expect(serialValues.count == 3)
            #expect(serialValues.allSatisfy { $0.count > 0 })
            // ASSERT result2.serials ARE all unique
            #expect(Set(serialValues).count == serialValues.count)
        }
    }

    // UTS: rest/integration/RSL1k5/idempotent-client-ids-0
    @Test(arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func test_RSL1k5_idempotent_publish_with_client_supplied_ids(useBinaryProtocol: Bool) async throws {
        try await withSandboxApp { app in
            // Setup
            let options = ARTClientOptions(key: app.defaultKey)
            options.restHost = SandboxApp.sandboxHost // the spec's endpoint: "nonprod:sandbox"
            options.useBinaryProtocol = useBinaryProtocol
            let client = ARTRest(options: options)
            let channelName = "idempotent-explicit-\(UUID().uuidString)"
            let channel = client.channels.get(channelName)

            // Test Steps
            let fixedId = "client-supplied-id-\(UUID().uuidString)"

            // Publish same message ID multiple times
            for i in 1...3 {
                let message = ARTMessage(name: "event", data: "data-\(i)")
                message.id = fixedId
                await self.awaitPublish(channel, message: message)
            }

            // Poll history until the message appears, keeping the page the poll settled on —
            // a refetch could hit a less-replicated frontend and under-return.
            guard let history = await pollUntil("channel history has at least one message", timeout: 10, interval: 0.5, {
                let items = await self.historyItemsQuietly(of: channel)
                return items.isEmpty ? nil : items
            }) else { return }

            // Verify only one message in history
            #expect(history.count == 1)
            #expect(history[0].id == fixedId)
            // The data should be from the first publish (subsequent ones are no-ops)
            #expect(history[0].data as? String == "data-1")
        }
    }

    // UTS: rest/integration/RSL1l1/publish-params-force-nack-0
    // DEVIATION: ably-cocoa exposes no publish-with-params API, so RSL1l1 cannot be exercised —
    // see deviations.md (Failing Tests). `params:` exists only on the message-edit methods
    // (updateMessage/deleteMessage/appendMessage), not on any publish overload.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil),
          arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func test_RSL1l1_publish_params_with_forceNack(useBinaryProtocol: Bool) async throws {
        // Setup (spec) — not expressible in ably-cocoa; kept for fidelity:
        //   client = Rest(options: ClientOptions(key: full_access_key, endpoint: "nonprod:sandbox"))
        //   channel_name = "force-nack-test-" + random_id()
        //   channel = client.channels.get(channel_name)

        // Test Steps (spec):
        //   AWAIT channel.publish(
        //     message: Message(name: "event", data: "data"),
        //     params: { "_forceNack": "true" }
        //   ) FAILS WITH error
        //   ASSERT error.code == 40099  # Specific code for forced nack
        // (no assertion: ARTRestChannel has no publish overload accepting request params — see
        // deviations.md)
        Issue.record("RSL1l1: ably-cocoa has no publish-with-params API — see deviations.md (Failing Tests)")
    }

    // UTS: rest/integration/RSL1m4/clientid-mismatch-rejected-0
    @Test(arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func test_RSL1m4_clientId_mismatch_rejection(useBinaryProtocol: Bool) async throws {
        try await withSandboxApp { app in
            // Setup
            // Create a token with a specific clientId
            let keyClientOptions = ARTClientOptions(key: app.defaultKey)
            keyClientOptions.restHost = SandboxApp.sandboxHost // the spec's endpoint: "nonprod:sandbox"
            keyClientOptions.useBinaryProtocol = useBinaryProtocol
            let keyClient = ARTRest(options: keyClientOptions)

            let token = try #require(await self.requestToken(
                keyClient, tokenParams: ARTTokenParams(clientId: "authenticated-client-id")))

            // Client using token with clientId
            let tokenClientOptions = ARTClientOptions(token: token)
            tokenClientOptions.restHost = SandboxApp.sandboxHost // the spec's endpoint: "nonprod:sandbox"
            tokenClientOptions.useBinaryProtocol = useBinaryProtocol
            let tokenClient = ARTRest(options: tokenClientOptions)

            let channelName = "clientid-mismatch-\(UUID().uuidString)"
            let channel = tokenClient.channels.get(channelName)

            // Test Steps
            let message = ARTMessage(name: "event",
                                     data: "data",
                                     clientId: "different-client-id") // Doesn't match authenticated clientId
            // AWAIT channel.publish(message: ...) FAILS WITH error
            let error = try #require(await self.publishError(channel, messages: [message]))
            #expect(error.code == 40012) // Incompatible clientId
            #expect(error.statusCode == 400)
        }
    }
}

extension PublishTests {
    /// Awaits `publish(name:data:)` expecting it to fail (the spec's `AWAIT publish FAILS WITH
    /// error`), returning the error — or nil, after recording an issue, if it unexpectedly
    /// succeeded (tests unwrap with `try #require`).
    private func publishError(_ channel: ARTRestChannel,
                              name: String,
                              data: String,
                              sourceLocation: SourceLocation = #_sourceLocation) async -> ARTErrorInfo? {
        await withCheckedContinuation { (continuation: CheckedContinuation<ARTErrorInfo?, Never>) in
            channel.publish(name, data: data, callback: { error in
                if error == nil {
                    Issue.record("publish(\(name)) unexpectedly succeeded", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: error)
            })
        }
    }

    /// Awaits `publish(messages:)` expecting it to fail, returning the error — or nil, after
    /// recording an issue, if it unexpectedly succeeded (tests unwrap with `try #require`).
    private func publishError(_ channel: ARTRestChannel,
                              messages: [ARTMessage],
                              sourceLocation: SourceLocation = #_sourceLocation) async -> ARTErrorInfo? {
        await withCheckedContinuation { (continuation: CheckedContinuation<ARTErrorInfo?, Never>) in
            channel.publish(messages, callback: { error in
                if error == nil {
                    Issue.record("publish(messages) unexpectedly succeeded", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: error)
            })
        }
    }

    /// Awaits the publish acknowledgement and returns the `ARTPublishResult` (the spec's
    /// `result = AWAIT channel.publish(name:data:)`), recording an issue on error.
    private func publishResult(_ channel: ARTRestChannel,
                               name: String,
                               data: String,
                               sourceLocation: SourceLocation = #_sourceLocation) async -> ARTPublishResult? {
        await withCheckedContinuation { (continuation: CheckedContinuation<ARTPublishResult?, Never>) in
            channel.publish(name, data: data, resultCallback: { result, error in
                if let error {
                    Issue.record("publish(\(name)) failed: \(error)", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: result)
            })
        }
    }

    /// Awaits the publish acknowledgement for an array of messages and returns the
    /// `ARTPublishResult` (the spec's `result = AWAIT channel.publish(messages:)`), recording an
    /// issue on error.
    private func publishResult(_ channel: ARTRestChannel,
                               messages: [ARTMessage],
                               sourceLocation: SourceLocation = #_sourceLocation) async -> ARTPublishResult? {
        await withCheckedContinuation { (continuation: CheckedContinuation<ARTPublishResult?, Never>) in
            channel.publish(messages, resultCallback: { result, error in
                if let error {
                    Issue.record("publish(messages) failed: \(error)", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: result)
            })
        }
    }

    /// Awaits the publish acknowledgement of a single pre-built message (the spec's
    /// `AWAIT channel.publish(message: ...)`), recording an issue on error.
    private func awaitPublish(_ channel: ARTRestChannel,
                              message: ARTMessage,
                              sourceLocation: SourceLocation = #_sourceLocation) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            channel.publish([message], callback: { error in
                if let error {
                    Issue.record("publish(\(message.id ?? "?")) failed: \(error)", sourceLocation: sourceLocation)
                }
                continuation.resume()
            })
        }
    }

    /// Fetches the channel's history (default query) and returns its items, recording an issue on
    /// error.
    private func historyItems(of channel: ARTRestChannel,
                              sourceLocation: SourceLocation = #_sourceLocation) async -> [ARTMessage] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[ARTMessage], Never>) in
            channel.history { result, error in
                if let error {
                    Issue.record("history() failed: \(error)", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: result?.items ?? [])
            }
        }
    }

    /// Non-reporting variant of `historyItems` for use inside `pollUntil` predicates: a transient
    /// `history()` error must surface as a retry — and, at worst, as the poll's own timeout issue —
    /// not fail the test. Returns an empty list on error.
    private func historyItemsQuietly(of channel: ARTRestChannel) async -> [ARTMessage] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[ARTMessage], Never>) in
            channel.history { result, _ in
                continuation.resume(returning: result?.items ?? [])
            }
        }
    }

    /// Requests a token from the sandbox (the spec's `AWAIT key_client.auth.requestToken(...)`),
    /// returning the issued `TokenDetails.token` string — the only field the tests use, and
    /// `ARTTokenDetails` is not Sendable so it cannot cross the continuation. Returns nil, after
    /// recording an issue, on failure (tests unwrap with `try #require`).
    private func requestToken(_ client: ARTRest,
                              tokenParams: ARTTokenParams,
                              sourceLocation: SourceLocation = #_sourceLocation) async -> String? {
        await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            client.auth.requestToken(tokenParams, with: nil) { tokenDetails, error in
                if let error {
                    Issue.record("requestToken failed: \(error)", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: tokenDetails?.token)
            }
        }
    }
}
