import Foundation
import Testing
import Ably
import Ably.Private

/// Shared helpers used by every tier (the cocoa counterpart of ably-java's `infra/Utils.kt`).
///
/// The unit tier's state waits live on `UTSTestCase` (`awaitConnectionState` / `awaitChannelState` /
/// `poll`) — they poll synchronously, which is fine when a frozen `MockTimeProvider` settles the SDK
/// in microseconds. The integration tier waits on *real* network and proxy state, where blocking the
/// test thread for seconds is wasteful, so it uses the async helpers below (the UTS specs'
/// anti-flake rule: no fixed blind waits — poll on observable state, with a short interval
/// between checks).

/// Suspends until `condition` returns `true`, polling every `interval` seconds, or records a test
/// failure once `timeout` (wall-clock seconds) elapses. Returns whether the condition was met.
///
/// The integration analogue of `UTSTestCase.poll` — e.g.
/// `await pollUntil("auth callback re-invoked") { authCallbackCount.count > original }`.
@discardableResult
func pollUntil(_ description: String,
               timeout: TimeInterval = 15,
               interval: TimeInterval = 0.1,
               sourceLocation: SourceLocation = #_sourceLocation,
               _ condition: () async -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !(await condition()) {
        if Date() >= deadline {
            Issue.record("Timed out after \(timeout)s polling for: \(description)", sourceLocation: sourceLocation)
            return false
        }
        do {
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        } catch {
            // Task cancelled — bail out instead of spinning a hot loop until the deadline.
            Issue.record("Cancelled while polling for: \(description)", sourceLocation: sourceLocation)
            return false
        }
    }
    return true
}

/// Suspends until `client.connection.state == expected` (the integration tier's `AWAIT_STATE`,
/// against a real backend — the async counterpart of `UTSTestCase.awaitConnectionState`).
///
/// A state-change listener latches the transition (registered before the current-state check), so a
/// transient state — e.g. `.disconnected` under the RTN15a immediate reconnect — cannot be missed.
@discardableResult
func awaitState(_ client: ARTRealtime,
                _ expected: ARTRealtimeConnectionState,
                timeout: TimeInterval = 15,
                sourceLocation: SourceLocation = #_sourceLocation) async -> Bool {
    let reached = Captured<Bool>()
    let listener = client.connection.on { change in
        if change.current == expected {
            reached.append(true)
        }
    }
    defer { client.connection.off(listener) }
    if client.connection.state == expected {
        reached.append(true)
    }
    return await pollUntil("connection.state == \(ARTRealtimeConnectionStateToStr(expected))",
                           timeout: timeout, sourceLocation: sourceLocation) {
        reached.count > 0
    }
}

/// Suspends until `channel.state == expected` (the integration tier's `AWAIT_STATE` for channels),
/// latching the transition like `awaitState` above.
@discardableResult
func awaitChannelState(_ channel: ARTRealtimeChannel,
                       _ expected: ARTRealtimeChannelState,
                       timeout: TimeInterval = 15,
                       sourceLocation: SourceLocation = #_sourceLocation) async -> Bool {
    let reached = Captured<Bool>()
    let listener = channel.on { change in
        if change.current == expected {
            reached.append(true)
        }
    }
    defer { channel.off(listener) }
    if channel.state == expected {
        reached.append(true)
    }
    return await pollUntil("channel '\(channel.name)'.state == \(ARTRealtimeChannelStateToStr(expected))",
                           timeout: timeout, sourceLocation: sourceLocation) {
        reached.count > 0
    }
}

/// Query parameters parsed from a URL (UTS `url.query_params`) — the counterpart of ably-java's
/// `parseQueryString`. Shared by the WS and HTTP mocks so the parsing lives in one place.
func parseQueryParams(of url: URL?) -> [String: String] {
    guard let url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let items = components.queryItems else { return [:] }
    var result: [String: String] = [:]
    for item in items where item.value != nil {
        result[item.name] = item.value
    }
    return result
}

// MARK: - HTTP support for integration infra

/// Error thrown by `httpRequest` when the response is not an HTTP response, or by callers on an
/// unexpected status code.
struct HTTPError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

/// Minimal async wrapper over `URLSession.dataTask` used by the integration infrastructure
/// (`SandboxApp`, `ProxyManager`, `ProxySession`). A continuation-based helper rather than
/// `URLSession.data(for:)` so the target's deployment floor stays where the rest of the suite is.
/// Returns the body and status code; callers decide which statuses are acceptable.
func httpRequest(_ request: URLRequest, session: URLSession) async throws -> (data: Data, status: Int) {
    try await withCheckedThrowingContinuation { continuation in
        session.dataTask(with: request) { data, response, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                continuation.resume(throwing: HTTPError("Non-HTTP response for \(request.url?.absoluteString ?? "?")"))
                return
            }
            continuation.resume(returning: (data ?? Data(), http.statusCode))
        }.resume()
    }
}

/// Builds a JSON request. `body` (when present) is serialised with `JSONSerialization`.
func jsonRequest(_ method: String, _ url: URL, body: Any? = nil) throws -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let body {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
    return request
}

/// A `URLSession` with finite timeouts so a stalled endpoint fails fast instead of hanging a suite.
func makeURLSession(requestTimeout: TimeInterval) -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = requestTimeout
    return URLSession(configuration: configuration)
}
