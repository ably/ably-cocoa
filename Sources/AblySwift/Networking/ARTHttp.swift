import Foundation

/// :nodoc:
public protocol ARTHTTPExecutor {
    func executeRequest(_ request: URLRequest, completion: ARTURLRequestCallback?) -> ARTCancellable?
}

/// :nodoc:
public protocol ARTURLSession {
    var queue: DispatchQueue { get }
    func get(_ request: URLRequest, completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> ARTCancellable
    func finishTasksAndInvalidate()
}

/// :nodoc:
public class ARTHttp: NSObject, ARTHTTPExecutor {
    
    private let urlSession: ARTURLSession
    private let logger: ARTInternalLog
    
    private static let configuredUrlSessionClassLock = NSLock()
    nonisolated(unsafe) private static var _configuredUrlSessionClass: AnyClass?
    
    private static var configuredUrlSessionClass: AnyClass? {
        get {
            configuredUrlSessionClassLock.lock()
            defer { configuredUrlSessionClassLock.unlock() }
            return _configuredUrlSessionClass
        }
        set {
            configuredUrlSessionClassLock.lock()
            defer { configuredUrlSessionClassLock.unlock() }
            _configuredUrlSessionClass = newValue
        }
    }
    
    // MARK: - Class Methods
    
    public static func setURLSessionClass(_ urlSessionClass: AnyClass?) {
        configuredUrlSessionClass = urlSessionClass
    }
    
    // MARK: - Initialization
    
    public init(queue: DispatchQueue, logger: ARTInternalLog) {
        self.logger = logger
        
        // Use configured URL session class or default to ARTURLSessionServerTrust
        let urlSessionClass = Self.configuredUrlSessionClass ?? ARTURLSessionServerTrust.self
        if urlSessionClass == ARTURLSessionServerTrust.self {
            self.urlSession = ARTURLSessionServerTrust(queue: queue)
        } else {
            // For now, fallback to default implementation
            // TODO: Properly handle custom URL session classes when needed
            self.urlSession = ARTURLSessionServerTrust(queue: queue)
        }
        
        super.init()
    }
    
    // MARK: - Properties
    
    public var queue: DispatchQueue {
        return urlSession.queue
    }
    
    // MARK: - Deallocation
    
    deinit {
        urlSession.finishTasksAndInvalidate()
    }
    
    // MARK: - ARTHTTPExecutor
    
    public func executeRequest(_ request: URLRequest, completion: ARTURLRequestCallback?) -> ARTCancellable? {
        var mutableRequest = request
        
        let debugBody = debugDescriptionOfBodyWithData(mutableRequest.httpBody)
        logger.debug("--> \(mutableRequest.httpMethod ?? "UNKNOWN") \(mutableRequest.url?.absoluteString ?? "nil")\n  Body: \(debugBody ?? "nil")\n  Headers: \(mutableRequest.allHTTPHeaderFields ?? [:])")
        
        return urlSession.get(mutableRequest) { [weak self] response, data, error in
            guard let self = self else { return }
            
            let httpResponse = response
            if let error = error {
                self.logger.error("<-- \(mutableRequest.httpMethod ?? "UNKNOWN") \(mutableRequest.url?.absoluteString ?? "nil"): error \(error)")
            } else if let httpResponse = httpResponse {
                let debugData = self.debugDescriptionOfBodyWithData(data)
                self.logger.debug("<-- \(mutableRequest.httpMethod ?? "UNKNOWN") \(mutableRequest.url?.absoluteString ?? "nil"): statusCode \(httpResponse.statusCode)\n  Data: \(debugData ?? "nil")\n  Headers: \(httpResponse.allHeaderFields)")
                
                if let headerErrorMessage = httpResponse.allHeaderFields[ARTHttpHeaderFieldErrorMessageKey] as? String,
                   !headerErrorMessage.isEmpty {
                    self.logger.warn("\(headerErrorMessage)")
                }
            }
            
            completion?(httpResponse, data, error)
        }
    }
    
    // MARK: - Private Methods
    
    private func debugDescriptionOfBodyWithData(_ data: Data?) -> String? {
        guard logger.logLevel >= ARTLogLevel.debug else {
            return nil
        }
        
        guard let data = data else {
            return nil
        }
        
        // Try to decode as UTF-8 string first
        if let requestBodyStr = String(data: data, encoding: .utf8) {
            return requestBodyStr
        }
        
        // Fall back to base64 encoding
        return data.base64EncodedString(options: .lineLength76Characters)
    }
}

// MARK: - Placeholder for ARTURLSessionServerTrust

/// :nodoc:
/// Placeholder for ARTURLSessionServerTrust - will be implemented when migrating SSL handling
public class ARTURLSessionServerTrust: NSObject, ARTURLSession {
    
    public let queue: DispatchQueue
    private let urlSession: URLSession
    
    public init(queue: DispatchQueue) {
        self.queue = queue
        self.urlSession = URLSession.shared // Temporary - will be properly configured later
        super.init()
    }
    
    public func get(_ request: URLRequest, completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> ARTCancellable {
        let task = urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(response as? HTTPURLResponse, data, error)
            }
        }
        
        task.resume()
        return task // URLSessionTask already conforms to ARTCancellable via cancel() method
    }
    
    public func finishTasksAndInvalidate() {
        // URLSession.shared doesn't need invalidation, but proper implementation will
    }
}