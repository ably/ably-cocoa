import Testing
import Foundation
import Ably

/// Acceptance test for the direct-sandbox integration infrastructure (`SandboxApp` alone — no
/// proxy, no fault rules) — not derived from a UTS spec. It proves the middle tier's shape works
/// end-to-end: sandbox provisioning → a real client connecting straight to the sandbox over TLS
/// (basic key auth is fine here, unlike through the proxy) → a publish/subscribe round-trip →
/// teardown.
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
@Suite(.serialized)
final class IntegrationSmokeTest {

    @Test(.enabled(if: ProcessInfo.processInfo.environment["UTS_INTEGRATION_SMOKE"] != nil),
          arguments: [false, true]) // useBinaryProtocol: false = JSON, true = msgpack
    func sandbox_infra_works_end_to_end(useBinaryProtocol: Bool) async throws {
        // Suite setup (what a real direct-sandbox test does in setup)
        let app = try await SandboxApp.create()
        #expect(app.defaultKey.hasPrefix(app.appId + "."))

        // A REAL client (no mocks) wired straight to the sandbox — TLS stays on, so the plain
        // sandbox key works (RSA1). Explicit hosts auto-disable fallback hosts (REC2c2).
        let options = ARTClientOptions(key: app.defaultKey)
        options.realtimeHost = SandboxApp.sandboxHost
        options.restHost = SandboxApp.sandboxHost
        options.useBinaryProtocol = useBinaryProtocol
        options.autoConnect = false
        let client = ARTRealtime(options: options)

        client.connect()
        await awaitState(client, .connected)
        #expect(client.connection.state == .connected)

        // Publish/subscribe round-trip on a fresh channel.
        let channel = client.channels.get("smoke-\(UUID().uuidString)")
        channel.attach()
        await awaitChannelState(channel, .attached, timeout: 10)

        let received = Captured<ARTMessage>()
        channel.subscribe { message in
            received.append(message)
        }
        channel.publish("event", data: "payload")
        await pollUntil("published message is echoed back to the subscriber", timeout: 10) {
            received.count == 1
        }
        #expect(received.first?.name == "event")
        #expect(received.first?.data as? String == "payload")

        // Teardown
        client.close()
        await awaitState(client, .closed, timeout: 10)
        await app.delete()
    }
}
