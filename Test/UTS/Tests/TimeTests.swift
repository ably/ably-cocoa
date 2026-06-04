import Testing
import Foundation
import Ably
import Ably.Private

/// Time API (RSC16)
/// Derived from https://github.com/ably/specification/blob/main/uts/rest/unit/time.md
@Suite(.serialized)
final class TimeTests: UTSTestCase {

    // UTS: rest/unit/RSC16/returns-server-time-0
    @Test
    func test_RSC16_time_returns_server_time() async throws {
        let serverTimeMs = 1_704_067_200_000 // 2024-01-01 00:00:00 UTC
        let capturedRequests = Captured<PendingHTTPRequest>()
        let mockHTTP = MockHTTP(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                capturedRequests.append(request)
                request.respondWith(status: 200, body: [serverTimeMs])
            }
        )
        installMock(mockHTTP)
        let rest = makeRest { options in
            options.key = "app.key:secret"
        }

        let result = await awaitTime(rest)

        // Result is a date matching the server timestamp.
        let date = try #require(result) // `time()` returns a `Date`
        #expect(Int(date.timeIntervalSince1970 * 1000) == serverTimeMs)

        // Verify the correct endpoint was called.
        #expect(capturedRequests.count == 1)
        let request = try #require(capturedRequests.first)
        #expect(request.method == "GET")
        #expect(request.url.path == "/time")
    }

    // UTS: rest/unit/RSC16/request-format-get-time-1
    @Test
    func test_RSC16_time_request_format() async throws {
        let capturedRequests = Captured<PendingHTTPRequest>()
        let mockHTTP = MockHTTP(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                capturedRequests.append(request)
                request.respondWith(status: 200, body: [1_704_067_200_000])
            }
        )
        installMock(mockHTTP)
        let rest = makeRest { options in
            options.key = "app.key:secret"
        }

        _ = await awaitTime(rest)

        #expect(capturedRequests.count == 1)
        let request = try #require(capturedRequests.first)

        // GET request to /time
        #expect(request.method == "GET")
        #expect(request.url.path == "/time")

        // Standard Ably headers
        #expect(request.headers["X-Ably-Version"] != nil)
        #expect(request.headers["Ably-Agent"] != nil)
    }

    // UTS: rest/unit/RSC16/no-auth-required-2
    @Test
    func test_RSC16_time_does_not_require_authentication() async throws {
        let capturedRequests = Captured<PendingHTTPRequest>()
        let mockHTTP = MockHTTP(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                capturedRequests.append(request)
                request.respondWith(status: 200, body: [1_704_067_200_000])
            }
        )
        installMock(mockHTTP)

        // Client has credentials, but time() should not use them.
        let rest = makeRest { options in
            options.key = "app.key:secret"
        }

        let result = await awaitTime(rest)

        // Should succeed
        #expect(result != nil)

        // Request should not have Authorization header even though client has credentials
        #expect(capturedRequests.count == 1)
        let request = try #require(capturedRequests.first)
        #expect(request.headers["Authorization"] == nil)
    }

    // UTS: rest/unit/RSC16/works-without-tls-3
    @Test
    func test_RSC16_time_works_without_TLS() async throws {
        let capturedRequests = Captured<PendingHTTPRequest>()
        let mockHTTP = MockHTTP(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                capturedRequests.append(request)
                request.respondWith(status: 200, body: [1_704_067_200_000])
            }
        )
        installMock(mockHTTP)

        // Client with API key but using token auth to avoid RSC18 restriction
        // on authenticated operations. time() should still work over HTTP.
        let rest = makeRest { options in
            options.key = "app.key:secret"
            options.tls = false
            options.useTokenAuth = true
        }

        // Succeeds without sending authentication over HTTP
        let result = await awaitTime(rest)
        #expect(result != nil)

        // Request should use HTTP (not HTTPS)
        #expect(capturedRequests.count == 1)
        let request = try #require(capturedRequests.first)
        #expect(request.url.scheme == "http")

        // Request should not have Authorization header
        #expect(request.headers["Authorization"] == nil)
    }

    // UTS: rest/unit/RSC16/error-propagated-4
    @Test
    func test_RSC16_time_error_handling() async throws {
        let mockHTTP = MockHTTP(
            onConnectionAttempt: { connection in connection.respondWithSuccess() },
            onRequest: { request in
                request.respondWith(status: 500, body: [
                    "error": ["message": "Internal server error", "code": 50000, "statusCode": 500],
                ])
            }
        )
        installMock(mockHTTP)
        let rest = makeRest { options in
            options.key = "app.key:secret"
        }

        // time() fails; the error carries the status code and Ably error code.
        let error = try #require(await awaitTimeError(rest))
        #expect(error.statusCode == 500)
        #expect(error.code == 50000)
    }
}

/// Test case helpers
extension TimeTests {

    /// Awaits `rest.time(...)`, returning the result (records an issue if it errors).
    private func awaitTime(_ rest: ARTRest, sourceLocation: SourceLocation = #_sourceLocation) async -> Date? {
        await withCheckedContinuation { (continuation: CheckedContinuation<Date?, Never>) in
            rest.time { date, error in
                if let error {
                    Issue.record("time() failed: \(error)", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: date)
            }
        }
    }

    /// Awaits `rest.time(...)` expecting it to fail, returning the error (records an issue if it succeeds).
    private func awaitTimeError(_ rest: ARTRest, sourceLocation: SourceLocation = #_sourceLocation) async -> ARTErrorInfo? {
        await withCheckedContinuation { (continuation: CheckedContinuation<ARTErrorInfo?, Never>) in
            rest.time { date, error in
                if error == nil {
                    Issue.record("expected time() to fail, got \(String(describing: date))", sourceLocation: sourceLocation)
                }
                continuation.resume(returning: error as? ARTErrorInfo)
            }
        }
    }
}
