import Testing
import Foundation
import Ably
import Ably.Private

/// Connection Recovery (RTN16)
/// Derived from https://github.com/ably/specification/blob/main/uts/realtime/unit/connection/connection_recovery_test.md
@Suite(.serialized)
final class ConnectionRecoveryTests: UTSTestCase {

    // UTS: realtime/unit/RTN16g/recovery-key-structure-0
    @Test
    func test_RTN16g_RTN16g1_createRecoveryKey_returns_string_with_connectionKey_msgSerial_and_channel_with_channelSerial_pairs() throws {
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "connection-1", connectionKey: "key-abc-123"))
        })
        installMock(wsProvider)
        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
        }

        // Connect
        client.connect()
        awaitConnectionState(client, .connected)

        // Get the WebSocket connection for sending mock responses
        let wsConnection = try #require(wsProvider.activeConnection)

        // Get two channels and simulate attaching them (including one with unicode name)
        let channelA = client.channels.get("channel-alpha")
        let channelB = client.channels.get("channel-éàü-世界")

        // Attach channel_a
        channelA.attach()
        wsConnection.sendToClient(.attached(channel: "channel-alpha", channelSerial: "serial-a-001"))
        awaitChannelState(channelA, .attached)

        // Attach channel_b (unicode name)
        channelB.attach()
        wsConnection.sendToClient(.attached(channel: "channel-éàü-世界", channelSerial: "serial-b-002"))
        awaitChannelState(channelB, .attached)

        // Create recovery key
        // Recovery key is not null (asserted by #require)
        let recoveryKeyString = try #require(client.connection.createRecoveryKey())

        // Deserialize the recovery key (JSON format per ably-js reference)
        let recoveryKey = try parseRecoveryKey(recoveryKeyString)

        // Contains connectionKey
        #expect(recoveryKey["connectionKey"] as? String == "key-abc-123")

        // Contains msgSerial (starts at 0 since no messages were sent)
        #expect(recoveryKey["msgSerial"] as? Int == 0)

        // Contains channelSerials map with both channels
        let channelSerials = try #require(recoveryKey["channelSerials"] as? [String: String])
        #expect(channelSerials["channel-alpha"] == "serial-a-001")

        // RTN16g1: Unicode channel name is correctly encoded in the serialized key
        #expect(channelSerials["channel-éàü-世界"] == "serial-b-002")

        // Verify round-trip: re-serializing and deserializing preserves the unicode name
        let reSerialized = try JSONSerialization.data(withJSONObject: recoveryKey)
        let reParsed = try #require(JSONSerialization.jsonObject(with: reSerialized) as? [String: Any])
        #expect((reParsed["channelSerials"] as? [String: String])?["channel-éàü-世界"] == "serial-b-002")

        closeClient(client)
    }

    // UTS: realtime/unit/RTN16g2/recovery-key-null-inactive-0
    @Test
    func test_RTN16g2_createRecoveryKey_returns_null_in_inactive_states_and_before_first_connect() throws {
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "connection-1", connectionKey: "key-1"))
        })
        installMock(wsProvider)
        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
        }

        // Before connecting (INITIALIZED state, no connectionKey)
        #expect(client.connection.createRecoveryKey() == nil)

        // Connect and verify recovery key is available when CONNECTED
        client.connect()
        awaitConnectionState(client, .connected)
        #expect(client.connection.createRecoveryKey() != nil)

        // Transition to CLOSING then CLOSED
        client.connection.close()
        awaitConnectionState(client, .closing)
        #expect(client.connection.createRecoveryKey() == nil)

        let wsConnection = try #require(wsProvider.activeConnection)
        wsConnection.sendToClientAndClose(.closed())

        awaitConnectionState(client, .closed)
        #expect(client.connection.createRecoveryKey() == nil)

        // All null cases verified inline above.
        // For FAILED and SUSPENDED states, create separate clients to test:

        // --- Test FAILED state ---
        let failedProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "conn-f", connectionKey: "key-f"))
        })
        installMock(failedProvider)
        let clientFailed = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
        }
        clientFailed.connect()
        awaitConnectionState(clientFailed, .connected)

        // Trigger FAILED via fatal ERROR
        let wsConnFailed = try #require(failedProvider.activeConnection)
        wsConnFailed.sendToClientAndClose(.error(code: 50000, statusCode: 500, message: "Fatal error"))
        awaitConnectionState(clientFailed, .failed)
        #expect(clientFailed.connection.createRecoveryKey() == nil)

        // --- Test SUSPENDED state ---
        // All connections fail after initial, to force SUSPENDED.
        // (Spec uses a shared connection_attempt_count; we use a provider-local counter so the
        //  initial attempt succeeds and every reconnect is refused — the spec's stated intent.)
        let suspendedAttempts = Captured<MockWebSocket>()
        let suspendedProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            suspendedAttempts.append(connection)
            if suspendedAttempts.count == 1 {
                connection.respondWithSuccess()
                // connectionStateTtl is in seconds here (2s); the spec's 2000 is the wire value (ms).
                connection.sendToClient(.connected(connectionId: "conn-s", connectionKey: "key-s", connectionStateTtl: 2))
            } else {
                connection.respondWithRefused()
            }
        })
        installMock(suspendedProvider)

        enableFakeTimers() // must precede client construction

        let clientSuspended = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
            options.disconnectedRetryTimeout = 0.5 // seconds (spec: 500ms)
            options.fallbackHosts = []
        }

        clientSuspended.connect()
        awaitConnectionState(clientSuspended, .connected)

        let wsConnSuspended = try #require(suspendedProvider.activeConnection)
        wsConnSuspended.simulateDisconnect()

        // Advance time until SUSPENDED (connectionStateTtl expires)
        for _ in 0..<10 {
            advanceTime(byMilliseconds: 1500)
            if clientSuspended.connection.state == .suspended {
                break
            }
        }

        awaitConnectionState(clientSuspended, .suspended)
        #expect(clientSuspended.connection.createRecoveryKey() == nil)

        closeClient(clientSuspended)
    }

    // UTS: realtime/unit/RTN16k/recover-query-param-0
    @Test
    func test_RTN16k_recover_option_adds_recover_query_param_to_WebSocket_URL() throws {
        // Construct a valid recoveryKey
        let recoveryKey = """
        {
          "connectionKey": "recovered-key-xyz",
          "msgSerial": 5,
          "channelSerials": {}
        }
        """
        let capturedConnectionAttempts = Captured<MockWebSocket>()
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            capturedConnectionAttempts.append(connection)
            connection.respondWithSuccess()
            if capturedConnectionAttempts.count == 1 {
                // First connection: successful recovery (same connectionId as implied by recoveryKey)
                connection.sendToClient(.connected(connectionId: "recovered-conn-id", connectionKey: "new-key-after-recovery"))
            } else {
                // Subsequent connection: resume after disconnect
                connection.sendToClient(.connected(connectionId: "recovered-conn-id", connectionKey: "resumed-key"))
            }
        })
        installMock(wsProvider)

        // Approach note: spec/ably-java run this on real timers; we enable fake timers so the
        // immediate-reconnect fires instantly via advanceTime instead of waiting a real ~0.1s delay
        enableFakeTimers()

        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
            options.recover = recoveryKey
        }

        // Connect - should use recover param
        client.connect()
        awaitConnectionState(client, .connected)

        // Simulate disconnect and reconnection
        let wsConnection = try #require(wsProvider.activeConnection)
        wsConnection.simulateDisconnect()

        // Advance to fire the immediate reconnect timer
        advanceTime(byMilliseconds: 1000)
        // Wait for resume reconnection
        awaitConnectionState(client, .connected)

        #expect(capturedConnectionAttempts.count == 2)

        // First connection attempt includes recover param with connectionKey from recoveryKey
        #expect(capturedConnectionAttempts[0].queryParams["recover"] == "recovered-key-xyz")
        // First connection attempt does NOT include resume param
        #expect(capturedConnectionAttempts[0].queryParams["resume"] == nil)

        // Second connection attempt uses resume (not recover) since client is now connected
        #expect(capturedConnectionAttempts[1].queryParams["resume"] == "new-key-after-recovery")
        #expect(capturedConnectionAttempts[1].queryParams["recover"] == nil)

        closeClient(client)
    }

    // UTS: realtime/unit/RTN16f/recover-initializes-msgserial-0
    @Test
    func test_RTN16f_recover_option_initializes_msgSerial_from_recoveryKey() throws {
        // Construct a recoveryKey with msgSerial of 42
        let recoveryKey = """
        {
          "connectionKey": "old-key",
          "msgSerial": 42,
          "channelSerials": {
            "test-channel": "ch-serial-1"
          }
        }
        """
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            // Successful recovery
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "recovered-conn", connectionKey: "new-key"))
        })
        installMock(wsProvider)
        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
            options.recover = recoveryKey
        }

        // Connect with recovery
        client.connect()
        awaitConnectionState(client, .connected)

        // Get WebSocket connection reference
        let wsConnection = try #require(wsProvider.activeConnection)

        // Attach the recovered channel
        let channel = client.channels.get("test-channel")
        channel.attach()
        wsConnection.sendToClient(.attached(channel: "test-channel", channelSerial: "ch-serial-updated"))
        awaitChannelState(channel, .attached)

        // Publish a message - the msgSerial should start from the recovered value (42)
        channel.publish("event", data: "data")

        // Capture the MESSAGE frame sent by the client
        poll("MESSAGE frame sent") {
            wsConnection.sentMessages.contains { $0.action == .message }
        }
        let messageFrame = wsConnection.sentMessages.first { $0.action == .message }

        // ACK the message
        wsConnection.sendToClient(.ack(msgSerial: 42, count: 1))

        // The first message published uses msgSerial from the recoveryKey
        #expect(messageFrame != nil)
        #expect(messageFrame?.msgSerial?.intValue == 42)

        closeClient(client)
    }

    // UTS: realtime/unit/RTN16f1/malformed-recovery-key-0
    @Test
    func test_RTN16f1_malformed_recoveryKey_logs_error_and_connects_normally() throws {
        let capturedConnectionAttempts = Captured<MockWebSocket>()
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            capturedConnectionAttempts.append(connection)
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "fresh-conn", connectionKey: "fresh-key"))
        })
        installMock(wsProvider)

        // Capture the SDK's logs so we can assert the malformed-key error is logged.
        let log = CapturingLog()
        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
            options.recover = "this-is-not-valid-json!!!" // Use a malformed (non-JSON) recover string
            options.logHandler = log
        }

        // Connect - should proceed as a normal connection (no recover param)
        client.connect()
        awaitConnectionState(client, .connected)

        // Connection succeeded normally
        #expect(client.connection.state == .connected)
        #expect(client.connection.id == "fresh-conn")
        #expect(client.connection.key == "fresh-key")

        let attempt = try #require(capturedConnectionAttempts.first)
        // No recover param was sent (malformed key was rejected)
        #expect(attempt.queryParams["recover"] == nil)

        // Also no resume param (this is a fresh connection)
        #expect(attempt.queryParams["resume"] == nil)

        // Only one connection attempt (normal connection, no retries)
        #expect(capturedConnectionAttempts.count == 1)

        // An error is logged about the malformed recovery key (captured via the injected logHandler).
        #expect(log.contains(level: .error, message: "recovery key"), "expected an error-level log mentioning the malformed recovery key")

        closeClient(client)
    }

    // UTS: realtime/unit/RTN16j/recover-channel-serials-0
    @Test
    func test_RTN16j_recover_option_instantiates_channels_from_recoveryKey_with_correct_channelSerials() throws {
        // Construct a recoveryKey with multiple channels
        let recoveryKey = """
        {
          "connectionKey": "old-key-abc",
          "msgSerial": 10,
          "channelSerials": {
            "channel-one": "serial-1-abc",
            "channel-two": "serial-2-def",
            "channel-üñîçöðé": "serial-3-unicode"
          }
        }
        """
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "recovered-conn", connectionKey: "new-key"))
        })
        installMock(wsProvider)
        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
            options.recover = recoveryKey
        }

        // Connect with recovery
        client.connect()
        awaitConnectionState(client, .connected)

        // RTN16j: Channels from the recoveryKey are instantiated
        let channelOne = client.channels.get("channel-one")
        let channelTwo = client.channels.get("channel-two")
        let channelUnicode = client.channels.get("channel-üñîçöðé")

        // Each channel has its channelSerial set from the recoveryKey
        #expect(channelOne.properties.channelSerial == "serial-1-abc")
        #expect(channelTwo.properties.channelSerial == "serial-2-def")
        #expect(channelUnicode.properties.channelSerial == "serial-3-unicode")

        // RTN16i: Channels are NOT automatically attached — the user must explicitly attach them.
        // They should be in INITIALIZED state (the library instantiated them but didn't attach).
        #expect(channelOne.state == .initialized)
        #expect(channelTwo.state == .initialized)
        #expect(channelUnicode.state == .initialized)

        // When the user attaches, the ATTACH message should include the channelSerial
        // (this enables the server to resume the channel from the correct point)
        let wsConnection = try #require(wsProvider.activeConnection)

        channelOne.attach()

        // Capture the ATTACH frame sent by the client
        poll("ATTACH frame for channel-one sent") {
            wsConnection.sentMessages.contains { $0.action == .attach && $0.channel == "channel-one" }
        }
        let sentFrames = wsConnection.sentMessages.filter { $0.action == .attach && $0.channel == "channel-one" }
        #expect(sentFrames.count == 1)
        #expect(sentFrames.first?.channelSerial == "serial-1-abc")

        // Complete the attachment
        wsConnection.sendToClient(.attached(channel: "channel-one", channelSerial: "serial-1-abc-updated"))
        awaitChannelState(channelOne, .attached)

        closeClient(client)
    }
}

/// Test case helpers
extension ConnectionRecoveryTests {

    /// Parses a JSON recovery key string into a dictionary.
    private func parseRecoveryKey(_ string: String) throws -> [String: Any] {
        let data = try #require(string.data(using: .utf8))
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
