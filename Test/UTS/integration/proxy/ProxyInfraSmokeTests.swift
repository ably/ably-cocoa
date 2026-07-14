// Proxy integration tests spawn a local uts-proxy process — macOS-only (see ProxyManager).
#if os(macOS)

import Testing
import Foundation
import Ably

/// Acceptance test for the integration infrastructure itself (`SandboxApp`, `ProxyManager`,
/// `ProxySession`) — not derived from a UTS spec. It proves the full chain works end-to-end:
/// binary sync → proxy launch → sandbox provisioning → a real client connecting through the proxy
/// → typed event-log assertions → teardown.
///
/// Needs outbound network (GitHub releases on first run, then the Ably sandbox), so it is gated
/// behind an env var and skipped by default:
///
/// ```bash
/// UTS_INTEGRATION_SMOKE=1 swift test --filter UTS.ProxyInfraSmokeTests
/// ```
@Suite(.serialized)
final class ProxyInfraSmokeTests {

    @Test(.enabled(if: ProcessInfo.processInfo.environment["UTS_INTEGRATION_SMOKE"] != nil))
    func proxy_and_sandbox_infra_work_end_to_end() async throws {
        // Suite setup (what a real proxy test does in setup)
        try await ProxyManager.shared.ensureProxy()
        let app = try await SandboxApp.create()
        #expect(app.defaultKey.hasPrefix(app.appId + "."))

        // Session with no rules — traffic passes through to the real sandbox.
        let session = try await ProxySession.create()
        #expect(session.proxyPort > 0)

        // A REAL client (no mocks) wired through the proxy. The proxy serves plain ws (tls=false),
        // and basic (key) auth is TLS-only (RSA1) — so, as in ably-java's proxy tests, authenticate
        // via an authCallback that signs a TokenRequest locally with the sandbox key.
        let signerOptions = ARTClientOptions(key: app.defaultKey)
        signerOptions.restHost = SandboxApp.sandboxHost
        let tokenSigner = ARTRest(options: signerOptions)

        let options = ARTClientOptions()
        options.authCallback = { params, callback in
            tokenSigner.auth.createTokenRequest(params, options: nil) { tokenRequest, error in
                callback(tokenRequest, error)
            }
        }
        options.connectThroughProxy(session)
        options.autoConnect = false
        let client = ARTRealtime(options: options)

        client.connect()
        await awaitState(client, .connected)
        #expect(client.connection.state == .connected)

        // The proxy recorded the handshake: a ws_connect and a server→client CONNECTED frame (4).
        let log = try await session.getLog()
        #expect(log.contains { $0.type == "ws_connect" })
        #expect(log.contains { event in
            event.type == "ws_frame" && event.direction == "server_to_client"
                && event.message?["action"] as? Int == 4
        })

        // Teardown (always runs in this linear happy path; failures above skip straight to Issue).
        client.close()
        await awaitState(client, .closed, timeout: 10)
        await session.close()
        await app.delete()
    }
}

#endif
