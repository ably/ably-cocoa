import XCTest
import Ably
import Ably.Private

/// Time API (RSC16)
/// Derived from https://github.com/ably/specification/blob/main/uts/rest/unit/time.md
final class TimeTests: UTSTestCase {

    // UTS: rest/unit/RSC16/returns-server-time-0
    func test_RSC16_time_returns_server_time() throws {
        let serverTimeMs = 1_704_067_200_000 // 2024-01-01 00:00:00 UTC
        var capturedRequests: [PendingHTTPRequest] = []
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

        let result = awaitTime(rest)

        // Result is a date matching the server timestamp.
        let date = try XCTUnwrap(result) // no need for `Date` assertion since `time()` returns `Date`
        XCTAssertEqual(Int(date.timeIntervalSince1970 * 1000), serverTimeMs)

        // Verify the correct endpoint was called.
        XCTAssertEqual(capturedRequests.count, 1)
        let request = try XCTUnwrap(capturedRequests.first)
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.url.path, "/time")
    }

    // UTS: rest/unit/RSC16/request-format-get-time-1
    func test_RSC16_time_request_format() throws {
        var capturedRequests: [PendingHTTPRequest] = []
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

        _ = awaitTime(rest)

        XCTAssertEqual(capturedRequests.count, 1)
        let request = try XCTUnwrap(capturedRequests.first)

        // GET request to /time
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.url.path, "/time")

        // Standard Ably headers
        XCTAssertNotNil(request.headers["X-Ably-Version"])
        XCTAssertNotNil(request.headers["Ably-Agent"])
    }

    // UTS: rest/unit/RSC16/no-auth-required-2
    func test_RSC16_time_does_not_require_authentication() throws {
        var capturedRequests: [PendingHTTPRequest] = []
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

        let result = awaitTime(rest)

        // Should succeed
        XCTAssertNotNil(result)

        // Request should not have Authorization header even though client has credentials
        XCTAssertEqual(capturedRequests.count, 1)
        let request = try XCTUnwrap(capturedRequests.first)
        XCTAssertNil(request.headers["Authorization"])
    }

    // UTS: rest/unit/RSC16/works-without-tls-3
    func test_RSC16_time_works_without_TLS() throws {
        var capturedRequests: [PendingHTTPRequest] = []
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
        let result = awaitTime(rest)
        XCTAssertNotNil(result)

        // Request should use HTTP (not HTTPS)
        XCTAssertEqual(capturedRequests.count, 1)
        let request = try XCTUnwrap(capturedRequests.first)
        XCTAssertEqual(request.url.scheme, "http")

        // Request should not have Authorization header
        XCTAssertNil(request.headers["Authorization"])
    }

    // UTS: rest/unit/RSC16/error-propagated-4
    func test_RSC16_time_error_handling() throws {
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
        let error = try XCTUnwrap(awaitTimeError(rest))
        XCTAssertEqual(error.statusCode, 500)
        XCTAssertEqual(error.code, 50000)
    }
}

/// Test case helpers
extension TimeTests {

    /// Awaits `rest.time(...)`, returning the result or failing on timeout/error.
    private func awaitTime(_ rest: ARTRest, file: StaticString = #file, line: UInt = #line) -> Date? {
        let expectation = expectation(description: "time()")
        var result: Date?
        rest.time { date, error in
            result = date
            if let error {
                XCTFail("time() failed: \(error)", file: file, line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Self.defaultAwaitTimeout)
        return result
    }

    /// Awaits `rest.time(...)` expecting it to fail, returning the error.
    private func awaitTimeError(_ rest: ARTRest, file: StaticString = #file, line: UInt = #line) -> ARTErrorInfo? {
        let expectation = expectation(description: "time() error")
        var capturedError: ARTErrorInfo?
        rest.time { date, error in
            capturedError = error as? ARTErrorInfo
            if error == nil {
                XCTFail("expected time() to fail, got \(String(describing: date))", file: file, line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Self.defaultAwaitTimeout)
        return capturedError
    }
}
