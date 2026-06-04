import Foundation
@preconcurrency import Ably
@preconcurrency import Ably.Private

/// The UTS `MockHttpClient` — a fake `ARTHTTPExecutor` that intercepts the SDK's outgoing HTTP
/// requests so tests can observe them and inject responses, with no real network. Installed via
/// `rest.internal.httpExecutor` (the cocoa mapping of the spec's `install_mock`).
///
/// Mirrors `uts/rest/unit/helpers/mock_http.md`. The cocoa HTTP seam is **request-level**
/// (`executeRequest:completion:`), so the connection phase is modelled lightly: `onConnectionAttempt`
/// fires once, before the first request, derived from that request's URL.
/// `respond_with_refused`, `timeout`, `dns_error` there make every request fail with the corresponding `NSError`;
/// a successful (or absent) connection handler lets requests through to `onRequest`.
final class MockHTTP: NSObject, ARTHTTPExecutor, @unchecked Sendable {
    typealias ConnectionHandler = @Sendable (PendingHTTPConnection) -> Void
    typealias RequestHandler = @Sendable (PendingHTTPRequest) -> Void

    private let onConnectionAttempt: ConnectionHandler?
    private let onRequest: RequestHandler?

    private let lock = NSLock()
    private var connectionResolved = false
    private var connectionError: NSError?

    /// The single place the lock is taken. The `onConnectionAttempt`/`onRequest` handlers are called
    /// *outside* it, because they call back into SDK/test code (which may re-enter `execute`) and
    /// holding the lock across that could deadlock.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    init(onConnectionAttempt: ConnectionHandler? = nil, onRequest: RequestHandler? = nil) {
        self.onConnectionAttempt = onConnectionAttempt
        self.onRequest = onRequest
        super.init()
    }

    // MARK: ARTHTTPExecutor

    func execute(_ request: URLRequest, completion callback: ((HTTPURLResponse?, Data?, Error?) -> Void)? = nil) -> (ARTCancellable & NSObjectProtocol)? {
        // Connection phase — fire onConnectionAttempt once, before the first request
        let firstConnection: PendingHTTPConnection? = withLock {
            guard !connectionResolved else { return nil }
            connectionResolved = true
            return PendingHTTPConnection(request: request)
        }
        if let firstConnection, let onConnectionAttempt {
            onConnectionAttempt(firstConnection)
            withLock { connectionError = firstConnection.resolvedError }
        }

        // Request phase — deliver to onRequest unless the connection failed
        if let failure = withLock({ connectionError }) {
            callback?(nil, nil, failure)
            return NoopCancellable()
        }
        onRequest?(PendingHTTPRequest(request: request, completion: callback))
        return NoopCancellable()
    }
}

/// A connection attempt (UTS `PendingConnection`). The cocoa HTTP seam doesn't expose real TCP, so
/// this is derived from the first request's URL and its outcome is applied to all requests.
final class PendingHTTPConnection: @unchecked Sendable {
    let host: String
    let port: Int
    let tls: Bool

    fileprivate private(set) var resolvedError: NSError?

    init(request: URLRequest) {
        let url = request.url
        self.tls = (url?.scheme?.lowercased() == "https")
        self.host = url?.host ?? ""
        self.port = url?.port ?? (tls ? 443 : 80)
    }

    /// Connection succeeds; requests proceed (UTS `respond_with_success`).
    func respondWithSuccess() { resolvedError = nil }
    /// TCP connection refused (UTS `respond_with_refused`).
    func respondWithRefused() { resolvedError = Self.urlError(.cannotConnectToHost) }
    /// Connection times out (UTS `respond_with_timeout`).
    func respondWithTimeout() { resolvedError = Self.urlError(.timedOut) }
    /// DNS resolution fails (UTS `respond_with_dns_error`).
    func respondWithDNSError() { resolvedError = Self.urlError(.cannotFindHost) }

    private static func urlError(_ code: URLError.Code) -> NSError {
        NSError(domain: NSURLErrorDomain, code: code.rawValue, userInfo: nil)
    }
}

/// A request the SDK made (UTS `PendingRequest`): inspectable, and respondable by the test.
final class PendingHTTPRequest: @unchecked Sendable {
    let request: URLRequest
    private let completion: ((HTTPURLResponse?, Data?, Error?) -> Void)?

    init(request: URLRequest, completion: ((HTTPURLResponse?, Data?, Error?) -> Void)?) {
        self.request = request
        self.completion = completion
    }

    var url: URL { request.url ?? URL(string: "https://invalid")! }
    var method: String { request.httpMethod ?? "GET" }
    var headers: [String: String] { request.allHTTPHeaderFields ?? [:] }
    var body: Data? { request.httpBody }

    /// Query parameters parsed from the request URL (UTS `url.query_params`).
    var queryParams: [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let items = components.queryItems else { return [:] }
        var result: [String: String] = [:]
        for item in items where item.value != nil { result[item.name] = item.value }
        return result
    }

    /// Sends an HTTP response (UTS `respond_with`). `body` may be `Data`, `String`, or a
    /// JSON-serialisable value (dictionary/array); defaults to a JSON content type.
    func respondWith(status: Int, body: Any, headers: [String: String] = [:]) {
        var headerFields = headers
        if headerFields["Content-Type"] == nil {
            headerFields["Content-Type"] = "application/json"
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headerFields)
        completion?(response, Self.data(from: body), nil)
    }

    /// Simulates a request timeout after the connection was established (UTS `respond_with_timeout`).
    func respondWithTimeout() {
        completion?(nil, nil, NSError(domain: NSURLErrorDomain, code: URLError.timedOut.rawValue, userInfo: nil))
    }

    private static func data(from body: Any) -> Data {
        switch body {
        case let data as Data: return data
        case let string as String: return Data(string.utf8)
        default: return (try? JSONSerialization.data(withJSONObject: body)) ?? Data()
        }
    }
}

/// No-op cancellable returned by `MockHTTP.execute` (the response is delivered synchronously, so
/// there's nothing to cancel).
private final class NoopCancellable: NSObject, ARTCancellable {
    func cancel() {}
}
