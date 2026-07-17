// Proxy integration tests spawn a local uts-proxy process — macOS-only (see ProxyManager).
#if os(macOS)

import Testing
import Foundation
import Ably

/// Acceptance test for the integration infrastructure itself (`SandboxApp`, `ProxyManager`,
/// `ProxySession`, `ProxyTestCase`) — not derived from a UTS spec. It proves the full chain works
/// end-to-end: binary sync → proxy launch → sandbox provisioning → a real client connecting
/// through the proxy → typed event-log assertions → teardown (handled by the base class).
///
/// Needs outbound network (GitHub releases on first run, then the Ably sandbox), so it is gated
/// behind an env var and skipped by default:
///
/// ```bash
/// UTS_INTEGRATION_SMOKE=1 swift test --filter UTS.ProxyInfraSmokeTests
/// ```
// TODO: Remove this infra acceptance (smoke) test once spec-derived integration/proxy
// tests exist and cover this ground (see Test/UTS/README.md §11.7).
@Suite(.serialized)
final class ProxyInfraSmokeTests: ProxyTestCase {

    @Test(.enabled(if: ProcessInfo.processInfo.environment["UTS_INTEGRATION_SMOKE"] != nil))
    func proxy_and_sandbox_infra_work_end_to_end() async throws {
        // Session with no rules — traffic passes through to the real sandbox. The base class
        // ensures the proxy is running and always closes the session + deletes the app.
        try await withProxySession(rules: []) { app, session in
            #expect(app.defaultKey.hasPrefix(app.appId + "."))
            #expect(session.proxyPort > 0)

            // A REAL client (no mocks) wired through the proxy with token auth (see
            // proxyClientOptions — basic key auth is TLS-only, RSA1).
            let options = proxyClientOptions(for: app, through: session)
            options.autoConnect = false

            try await withRealtimeClient(options) { client in
                await runScenario(client, session)
            }
        }
    }

    /// The happy-path scenario. Each wait is guarded (a timeout already records an `Issue`), and
    /// the control-plane `getLog()` failure is recorded rather than thrown — the base class's
    /// teardown runs regardless.
    private func runScenario(_ client: ARTRealtime, _ session: ProxySession) async {
        client.connect()
        guard await awaitState(client, .connected) else { return }
        #expect(client.connection.state == .connected)

        // The proxy recorded the handshake: a ws_connect and a server→client CONNECTED frame (4).
        let log: [ProxyEvent]
        do {
            log = try await session.getLog()
        } catch {
            Issue.record("Proxy getLog() failed: \(error)")
            return
        }
        #expect(log.contains { $0.type == "ws_connect" })
        #expect(log.contains { event in
            event.type == "ws_frame" && event.direction == "server_to_client"
                && event.message?["action"] as? Int == 4
        })
    }
}

#endif
