import Foundation

// swift-migration: original location ARTHTTPPaginatedResponse.h, line 11 and ARTHTTPPaginatedResponse.m, line 14
public class ARTHTTPPaginatedResponse: ARTPaginatedResult<NSDictionary> {
    
    // swift-migration: original location ARTHTTPPaginatedResponse+Private.h, line 11
    internal var response: HTTPURLResponse
    
    // swift-migration: original location ARTHTTPPaginatedResponse+Private.h, line 13 and ARTHTTPPaginatedResponse.m, line 16
    internal init(response: HTTPURLResponse,
                 items: [Any],
                 rest: ARTRestInternal,
                 relFirst: URLRequest?,
                 relCurrent: URLRequest?,
                 relNext: URLRequest?,
                 responseProcessor: @escaping ARTPaginatedResultResponseProcessor,
                 wrapperSDKAgents: [String: String]?,
                 logger: ARTInternalLog) {
        self.response = response
        super.init(items: items, rest: rest, relFirst: relFirst, relCurrent: relCurrent, relNext: relNext, responseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: logger)
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 16 and ARTHTTPPaginatedResponse.m, line 32
    /// The HTTP status code of the response.
    public var statusCode: Int {
        return response.statusCode
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 21 and ARTHTTPPaginatedResponse.m, line 36
    /// Whether `statusCode` indicates success. This is equivalent to `200 <= statusCode < 300`.
    public var success: Bool {
        return response.statusCode >= 200 && response.statusCode < 300
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 26 and ARTHTTPPaginatedResponse.m, line 40
    /// The error code if the `x-ably-errorcode` HTTP header is sent in the response.
    public var errorCode: Int {
        let code = response.allHeaderFields[ARTHttpHeaderFieldErrorCodeKey] as? String
        return Int(code ?? "") ?? 0
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 31 and ARTHTTPPaginatedResponse.m, line 45
    /// The error message if the `x-ably-errormessage` HTTP header is sent in the response.
    public var errorMessage: String? {
        return response.allHeaderFields[ARTHttpHeaderFieldErrorMessageKey] as? String
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 36 and ARTHTTPPaginatedResponse.m, line 50
    /// The headers of the response.
    public var headers: [String: String] {
        // swift-migration: preserving original behavior of returning all header fields
        var result: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            if let keyStr = key as? String, let valueStr = value as? String {
                result[keyStr] = valueStr
            }
        }
        return result
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 43 and ARTHTTPPaginatedResponse.m, line 54
    /// Returns a new `ARTHTTPPaginatedResponse` for the first page of results.
    /// - Parameter callback: A callback for retriving an `ARTHTTPPaginatedResponse` object with an array of `NSDictionary` objects.
    public override func first(_ callback: @escaping ARTHTTPPaginatedCallback) {
        var wrappedCallback = callback
        let userCallback = callback
        wrappedCallback = { result, error in
            self.userQueue.async {
                userCallback(result, error)
            }
        }

        Self.executePaginated(rest, withRequest: relFirst!, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse.h, line 50 and ARTHTTPPaginatedResponse.m, line 67
    /// Returns a new `ARTHTTPPaginatedResponse` loaded with the next page of results. If there are no further pages, then `nil` is returned.
    /// - Parameter callback: A callback for retriving an `ARTHTTPPaginatedResponse` object with an array of `NSDictionary` objects.
    public override func next(_ callback: @escaping ARTHTTPPaginatedCallback) {
        var wrappedCallback = callback
        let userCallback = callback
        wrappedCallback = { result, error in
            self.userQueue.async {
                userCallback(result, error)
            }
        }

        if relNext == nil {
            // If there is no next page, we can't make a request, so we answer the callback
            // with a nil PaginatedResult. That's why the callback has the result as nullable
            // anyway. (That, and that it can fail.)
            wrappedCallback(nil, nil)
            return
        }

        Self.executePaginated(rest, withRequest: relNext!, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
    }
    
    // swift-migration: original location ARTHTTPPaginatedResponse+Private.h, line 28 and ARTHTTPPaginatedResponse.m, line 88
    public class func executePaginated(_ rest: ARTRestInternal,
                                           withRequest request: URLRequest,
                                           wrapperSDKAgents: [String: String]?,
                                           logger: ARTInternalLog,
                                           callback: @escaping ARTHTTPPaginatedCallback) {
        ARTLogDebug(logger, "HTTP Paginated request: \(request)")

        _ = rest.executeRequest(request, withAuthOption: ARTAuthentication.on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
            if let error = error, (error as NSError).domain != ARTAblyErrorDomain {
                callback(nil, ARTErrorInfo.createFromNSError(error))
                return
            }

            if let response = response {
                ARTLogDebug(logger, "HTTP Paginated response: \(response)")
            }
            if let data = data {
                ARTLogDebug(logger, "HTTP Paginated response data: \(String(data: data, encoding: .utf8) ?? "")")
            }

            var decodeError: Error? = nil

            let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data, errorPtr in
                if let encoder = rest.encoders[response?.mimeType ?? ""], let data = data {
                    do {
                        return try encoder.decodeToArray(data)?.map { $0 as Any }
                    } catch {
                        errorPtr = error
                        return nil
                    }
                }
                return nil
            }
            let items = error != nil ? [] : (responseProcessor(response, data, &decodeError) ?? [])

            if let decodeError = decodeError {
                callback(nil, ARTErrorInfo.createFromNSError(decodeError))
                return
            }

            guard let httpResponse = response else {
                callback(nil, ARTErrorInfo.create(withCode: 50000, message: "No HTTP response received"))
                return
            }

            let links = httpResponse.extractLinks()

            let firstRel = URLRequest.requestWithPath(links?["first"], relativeTo: request)
            let currentRel = URLRequest.requestWithPath(links?["current"], relativeTo: request)
            let nextRel = URLRequest.requestWithPath(links?["next"], relativeTo: request)

            let result = ARTHTTPPaginatedResponse(response: httpResponse, 
                                                items: items, 
                                                rest: rest, 
                                                relFirst: firstRel, 
                                                relCurrent: currentRel, 
                                                relNext: nextRel, 
                                                responseProcessor: responseProcessor, 
                                                wrapperSDKAgents: wrapperSDKAgents, 
                                                logger: logger)

            callback(result, nil)
        }
    }
}