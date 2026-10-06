import Testing
import Foundation
import AblyPubSubDevice
import AblyPubSubDevice.Private

/// Fallback Hosts Tests (RTN17f1)
/// Derived from https://github.com/ably/specification/blob/main/uts/realtime/unit/connection/fallback_hosts_test.md
@Suite(.serialized)
final class FallbackHostsTests: UTSTestCase {

    // UTS: realtime/unit/RTN17f1/disconnected-5xx-fallback-0
    @Test
    func test_RTN17f1_disconnected_with_5xx_status_triggers_fallback() {
        // Setup
        let connectionAttempts = Captured<String>()

        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            connectionAttempts.append(connection.url.host ?? "")

            if connectionAttempts.count == 1 {
                // Primary domain: connect then send DISCONNECTED with 503 and close
                connection.respondWithSuccess()
                connection.sendToClientAndClose(.disconnected(
                    code: 50003,
                    statusCode: 503,
                    message: "Service temporarily unavailable"
                ))
            } else {
                // Fallback domain: succeeds
                connection.respondWithSuccess()
                connection.sendToClient(.connected(
                    connectionId: "connection-id",
                    connectionKey: "connection-key",
                    maxIdleInterval: 15,
                    connectionStateTtl: 120
                ))
            }
        })
        installMock(wsProvider)

        // The SDK checks connectivity before it tries a fallback host (RTN17j). The spec's setup
        // doesn't mock that request; see deviations.md.
        let mockHTTP = MockHTTPClient(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in request.respondWith(status: 200, body: "yes\n") }
        )
        installMock(mockHTTP)

        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
            options.autoConnect = false
        }

        // Test Steps
        // Start connection
        client.connect()

        // Wait for successful connection via fallback
        awaitConnectionState(client, .connected, timeout: 10)

        // Assertions
        // Should have tried at least 2 hosts
        #expect(connectionAttempts.count >= 2)

        // First was primary, second was fallback
        #expect(connectionAttempts[0].contains("realtime.ably"))
        #expect(connectionAttempts[1].contains("fallback"))
        closeClient(client)
    }
}
