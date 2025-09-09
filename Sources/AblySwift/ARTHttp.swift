import Foundation

// swift-migration: original location ARTHttp.h, line 14
/// :nodoc:
internal protocol ARTHTTPExecutor {
    // swift-migration: original location ARTHttp.h, line 16
    func executeRequest(_ request: URLRequest, completion: ARTURLRequestCallback?) -> (any ARTCancellable)?
}

// swift-migration: original location ARTHttp.m, line 12
private var configuredUrlSessionClass: AnyClass? = nil

// swift-migration: original location ARTHttp.h, line 22 and ARTHttp.m, line 16
/// :nodoc:
internal class ARTHttp: NSObject, ARTHTTPExecutor {
    
    // swift-migration: original location ARTHttp.m, line 8
    internal let urlSession: any ARTURLSession
    
    // swift-migration: original location ARTHttp.m, line 17
    private let _logger: ARTInternalLog
    
    // swift-migration: original location ARTHttp.h, line 24 and ARTHttp.m, line 20
    internal class func setURLSessionClass(_ urlSessionClass: AnyClass) {
        configuredUrlSessionClass = urlSessionClass
    }
    
    // swift-migration: original location ARTHttp.h, line 27 and ARTHttp.m, line 24
    internal init(queue: DispatchQueue, logger: ARTInternalLog) {
        let urlSessionClass = configuredUrlSessionClass ?? ARTURLSessionServerTrust.self
        self.urlSession = (urlSessionClass as! ARTURLSession.Type).init(queue)
        self._logger = logger
        super.init()
    }
    
    // swift-migration: original location ARTHttp.m, line 34
    internal var logger: ARTInternalLog {
        return _logger
    }
    
    // swift-migration: original location ARTHttp+Private.h, line 7 and ARTHttp.m, line 38
    internal var queue: DispatchQueue {
        return urlSession.queue
    }
    
    // swift-migration: original location ARTHttp.m, line 42
    deinit {
        urlSession.finishTasksAndInvalidate()
    }
    
    // swift-migration: original location ARTHttp.h, line 16 and ARTHttp.m, line 46
    internal func executeRequest(_ request: URLRequest, completion callback: ARTURLRequestCallback?) -> (any ARTCancellable)? {
        let bodyString = debugDescriptionOfBody(with: request.httpBody)
        ARTLogDebug(self.logger, "--> \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")\n  Body: \(bodyString ?? "")\n  Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        return urlSession.get(request) { [weak self] response, data, error in
            guard let self = self else { return }
            
            let httpResponse = response
            if let error = error {
                ARTLogError(self.logger, "<-- \(request.httpMethod ?? "") \(request.url?.absoluteString ?? ""): error \(error)")
            } else if let httpResponse = httpResponse {
                let dataString = self.debugDescriptionOfBody(with: data)
                ARTLogDebug(self.logger, "<-- \(request.httpMethod ?? "") \(request.url?.absoluteString ?? ""): statusCode \(httpResponse.statusCode)\n  Data: \(dataString ?? "")\n  Headers: \(httpResponse.allHeaderFields)\n")
                let headerErrorMessage = httpResponse.allHeaderFields[ARTHttpHeaderFieldErrorMessageKey] as? String
                if let headerErrorMessage = headerErrorMessage, !headerErrorMessage.isEmpty {
                    ARTLogWarn(self.logger, "\(headerErrorMessage)")
                }
            }
            callback?(httpResponse, data, error)
        }
    }
    
    // swift-migration: original location ARTHttp.m, line 64
    private func debugDescriptionOfBody(with data: Data?) -> String? {
        guard let data = data else { return nil }
        
        if self.logger.logLevel.rawValue <= ARTLogLevel.debug.rawValue {
            var requestBodyStr = String(data: data, encoding: .utf8)
            if requestBodyStr == nil {
                requestBodyStr = data.base64EncodedString(options: .lineLength76Characters)
            }
            return requestBodyStr
        }
        return nil
    }
}