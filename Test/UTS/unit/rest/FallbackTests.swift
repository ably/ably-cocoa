import Testing
import Foundation
import Ably
import Ably.Private

/// Host fallback (RSC15)
/// Derived from https://github.com/ably/specification/blob/main/uts/rest/unit/fallback.md
@Suite(.serialized)
final class FallbackTests: UTSTestCase {

    // UTS: rest/unit/RSC15l4/cloudfront-error-triggers-fallback-0
    @Test
    func test_RSC15l4_cloudfront_error_triggers_fallback() async throws {
        // Setup
        let capturedRequests = Captured<PendingHTTPRequest>()

        let mockHTTP = MockHTTPClient(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                capturedRequests.append(request)
                if capturedRequests.count == 1 {
                    request.respondWith(status: 403, body: ["error": "Forbidden"], headers: ["Server": "CloudFront"])
                } else {
                    // The spec writes this body as { "time": 1234567890000 }; the SDK reads /time as an array.
                    request.respondWith(status: 200, body: [1_234_567_890_000])
                }
            }
        )
        installMock(mockHTTP)

        let rest = makeRest { options in options.key = "appId.keyId:keySecret" }

        // Test Steps
        _ = try await awaitTime(rest)

        // Assertions
        #expect(capturedRequests.count == 2)
        // ASSERT mock_http.captured_requests[0].url.host == "main.realtime.ably.net"
        // ASSERT mock_http.captured_requests[1].url.host != "main.realtime.ably.net"
        // Adapted to the client's own primary host; see deviations.md (RSC15l4).
        let primaryHost = rest.internal.options.restUrl().host
        #expect(capturedRequests[0].url.host == primaryHost)
        #expect(capturedRequests[1].url.host != primaryHost)
    }

    // UTS: rest/unit/RSC15l/http-4xx-no-fallback-5
    @Test(arguments: [400, 401, 404])
    func test_RSC15l_http_4xx_no_fallback(statusCode: Int) async throws {
        // Setup
        let capturedRequests = Captured<PendingHTTPRequest>()

        let mockHTTP = MockHTTPClient(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                capturedRequests.append(request)
                request.respondWith(status: statusCode, body: ["error": ["code": statusCode * 100]])
            }
        )
        installMock(mockHTTP)

        let rest = makeRest { options in options.key = "appId.keyId:keySecret" }

        // Test Steps
        let error = try await awaitTimeError(rest)

        // Assertions
        #expect(error.statusCode == statusCode)

        // Should NOT have retried
        #expect(capturedRequests.count == 1)
    }
}
