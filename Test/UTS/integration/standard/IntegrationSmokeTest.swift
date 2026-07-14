import Testing
import Foundation
import Ably

/// Acceptance test for the direct-sandbox integration infrastructure (`SandboxApp` +
/// `IntegrationTestCase` — no proxy, no fault rules) — not derived from a UTS spec. It proves the
/// middle tier's shape works end-to-end: sandbox provisioning → a real client connecting straight
/// to the sandbox over TLS (basic key auth is fine here, unlike through the proxy) → a
/// publish/subscribe round-trip → teardown (handled by the base class).
///
/// Runs once per protocol variant (the UTS integration specs' `PROTOCOL` dimension, ably-java's
/// `@ParameterizedTest` over `useBinaryProtocol`): `false` = JSON, `true` = msgpack. Only the
/// proxy tier is JSON-only (the proxy can't inspect binary frames) — direct-sandbox tests must
/// exercise both.
///
/// Needs outbound network (the Ably sandbox), so it is gated behind an env var and skipped by
/// default:
///
/// ```bash
/// UTS_INTEGRATION_SMOKE=1 swift test --filter UTS.IntegrationSmokeTest
/// ```
// TODO: Remove this infra acceptance (smoke) test once spec-derived integration/standard
// tests exist and cover this ground (see Test/UTS/README.md §11.7).
@Suite(.serialized)
final class IntegrationSmokeTest: IntegrationTestCase {

    @Test(.enabled(if: ProcessInfo.processInfo.environment["UTS_INTEGRATION_SMOKE"] != nil),
          arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func sandbox_infra_works_end_to_end(useBinaryProtocol: Bool) async throws {
        try await withSandboxApp { app in
            #expect(app.defaultKey.hasPrefix(app.appId + "."))

            // A REAL client (no mocks) wired straight to the sandbox — TLS stays on, so the plain
            // sandbox key works (RSA1). Explicit hosts auto-disable fallback hosts (REC2c2).
            let options = ARTClientOptions(key: app.defaultKey)
            options.realtimeHost = SandboxApp.sandboxHost
            options.restHost = SandboxApp.sandboxHost
            options.useBinaryProtocol = useBinaryProtocol
            options.autoConnect = false

            try await withRealtimeClient(options) { client in
                await runScenario(client)
            }
        }
    }

    /// The happy-path scenario. Each wait is guarded: on timeout an `Issue` is already recorded
    /// by the helper, so just stop instead of driving a client in the wrong state — the base
    /// class's teardown runs regardless.
    private func runScenario(_ client: ARTRealtime) async {
        client.connect()
        guard await awaitState(client, .connected) else { return }
        #expect(client.connection.state == .connected)

        // Publish/subscribe round-trip on a fresh channel (fresh name per variant/retry, so runs
        // never collide on server-side channel state).
        let channel = client.channels.get("smoke-\(UUID().uuidString)")
        channel.attach()
        guard await awaitChannelState(channel, .attached, timeout: 10) else { return }

        let received = Captured<ARTMessage>()
        channel.subscribe { message in
            received.append(message)
        }
        channel.publish("event", data: "payload")
        guard await pollUntil("published message is echoed back to the subscriber", timeout: 10, {
            received.count == 1
        }) else { return }
        #expect(received.first?.name == "event")
        #expect(received.first?.data as? String == "payload")
    }
}
