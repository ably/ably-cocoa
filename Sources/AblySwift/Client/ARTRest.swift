//
//  ARTRest.swift
//  Ably
//
//  Created by Swift Migration on 2024-01-01.
//  Copyright © 2024 Ably Real-time Ltd. All rights reserved.
//

import Foundation

// MARK: - ARTRestInstanceMethodsProtocol

/// Protocol containing non-initializer instance methods provided by the ARTRest client class.
public protocol ARTRestInstanceMethodsProtocol {
    
    /// Retrieves the time from the Ably service.
    /// - Parameter callback: A callback for receiving the time as a Date object.
    func time(_ callback: @escaping ARTDateTimeCallback)
    
    /// Makes a REST request to a provided path.
    /// - Parameters:
    ///   - method: The request method to use, such as GET, POST.
    ///   - path: The request path.
    ///   - params: The parameters to include in the URL query of the request.
    ///   - body: The JSON body of the request.
    ///   - headers: Additional HTTP headers to include in the request.
    ///   - callback: A callback for retrieving ARTHTTPPaginatedResponse object.
    ///   - errorPtr: A reference to the NSError object where error information will be saved.
    /// - Returns: In case of failure returns false and the error information can be retrieved via the error parameter.
    func request(
        _ method: String,
        path: String,
        params: [String: String]?,
        body: Any?,
        headers: [String: String]?,
        callback: @escaping ARTHTTPPaginatedCallback,
        error errorPtr: inout NSError?
    ) -> Bool
    
    /// Queries the REST /stats API and retrieves your application's usage statistics.
    /// - Parameter callback: A callback for retrieving an ARTPaginatedResult object with an array of ARTStats objects.
    func stats(_ callback: @escaping ARTPaginatedStatsCallback) -> Bool
    
    /// Queries the REST /stats API with a query and retrieves your application's usage statistics.
    /// - Parameters:
    ///   - query: An ARTStatsQuery object.
    ///   - callback: A callback for retrieving an ARTPaginatedResult object with an array of ARTStats objects.
    ///   - errorPtr: A reference to the NSError object where error information will be saved.
    /// - Returns: In case of failure returns false and the error information can be retrieved via the error parameter.
    func stats(
        _ query: Any?,
        callback: @escaping ARTPaginatedStatsCallback,
        error errorPtr: inout NSError?
    ) -> Bool
    
    #if TARGET_OS_IOS
    /// Retrieves an ARTLocalDevice object that represents the current state of the device as a target for push notifications.
    var device: ARTLocalDevice { get }
    #endif
}

// MARK: - ARTRestProtocol

/// The protocol upon which the top level object ARTRest is implemented.
public protocol ARTRestProtocol: ARTRestInstanceMethodsProtocol {
    
    /// Construct an ARTRest object using an Ably ARTClientOptions object.
    /// - Parameter options: A ARTClientOptions object to configure the client connection to Ably.
    init(options: ARTClientOptions)
    
    /// Constructs a ARTRest object using an Ably API key.
    /// - Parameter key: The Ably API key used to validate the client.
    init(key: String)
    
    /// Constructs a ARTRest object using an Ably token string.
    /// - Parameter token: The Ably token string used to validate the client.
    init(token: String)
}

// MARK: - ARTRest

/// A client that offers a simple stateless API to interact directly with Ably's REST API.
public class ARTRest: NSObject, ARTRestProtocol, @unchecked Sendable {
    
    // MARK: - Public Properties
    
    /// An ARTRestChannels object.
    public var channels: Any {
        // Placeholder implementation
        return "ARTRestChannels placeholder"
    }
    
    /// An ARTAuth object.
    public var auth: Any {
        // Placeholder implementation
        return "ARTAuth placeholder"
    }
    
    /// An ARTPush object.
    public var push: Any {
        // Placeholder implementation
        return "ARTPush placeholder"
    }
    
    #if os(iOS)
    /// Retrieves an ARTLocalDevice object that represents the current state of the device as a target for push notifications.
    public var device: Any {
        // Placeholder implementation
        return "ARTLocalDevice placeholder"
    }
    #endif
    
    // MARK: - Internal Properties
    
    internal let _internal: ARTRestInternalSwift
    private let _dealloc: ARTQueuedDealloc?
    
    // MARK: - Initialization
    
    /// Construct an ARTRest object using an Ably ARTClientOptions object.
    /// - Parameter options: A ARTClientOptions object to configure the client connection to Ably.
    public required init(options: ARTClientOptions) {
        self._internal = ARTRestInternalSwift(options: options)
        self._dealloc = nil // Placeholder - would need proper ARTQueuedDealloc implementation
        super.init()
    }
    
    /// Constructs a ARTRest object using an Ably API key.
    /// - Parameter key: The Ably API key used to validate the client.
    public required init(key: String) {
        self._internal = ARTRestInternalSwift(key: key)
        self._dealloc = nil // Placeholder - would need proper ARTQueuedDealloc implementation
        super.init()
    }
    
    /// Constructs a ARTRest object using an Ably token string.
    /// - Parameter token: The Ably token string used to validate the client.
    public required init(token: String) {
        self._internal = ARTRestInternalSwift(token: token)
        self._dealloc = nil // Placeholder - would need proper ARTQueuedDealloc implementation
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Retrieves the time from the Ably service.
    /// - Parameter callback: A callback for receiving the time as a Date object.
    public func time(_ callback: @escaping ARTDateTimeCallback) {
        _internal.time(wrapperSDKAgents: nil, completion: callback)
    }
    
    /// Makes a REST request to a provided path.
    public func request(
        _ method: String,
        path: String,
        params: [String: String]?,
        body: Any?,
        headers: [String: String]?,
        callback: @escaping ARTHTTPPaginatedCallback,
        error errorPtr: inout NSError?
    ) -> Bool {
        return _internal.request(
            method,
            path: path,
            params: params,
            body: body,
            headers: headers,
            wrapperSDKAgents: nil,
            callback: callback,
            error: &errorPtr
        )
    }
    
    /// Queries the REST /stats API and retrieves your application's usage statistics.
    public func stats(_ callback: @escaping ARTPaginatedStatsCallback) -> Bool {
        return _internal.stats(wrapperSDKAgents: nil, completion: callback)
    }
    
    /// Queries the REST /stats API with a query and retrieves your application's usage statistics.
    public func stats(
        _ query: Any?,
        callback: @escaping ARTPaginatedStatsCallback,
        error errorPtr: inout NSError?
    ) -> Bool {
        return _internal.stats(
            query,
            wrapperSDKAgents: nil,
            callback: callback,
            error: &errorPtr
        )
    }
    
    // MARK: - Internal Methods
    
    /// Execute a closure with the internal ARTRestInternalSwift asynchronously.
    internal func internalAsync(_ use: @escaping (ARTRestInternalSwift) -> Void) {
        DispatchQueue.global().async {
            use(self._internal)
        }
    }
}

// MARK: - ARTRestInternalSwift

/// ARTRest private methods that are used internally and for internal testing.
internal class ARTRestInternalSwift: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    internal let options: ARTClientOptions
    internal let queue: DispatchQueue
    internal let userQueue: DispatchQueue
    
    /// Must be atomic!
    internal var prioritizedHost: String?
    
    // Private properties
    private let logger: ARTInternalLog
    
    // MARK: - Initialization
    
    internal convenience init(options: ARTClientOptions) {
        let logger = ARTInternalLog()
        self.init(options: options, realtime: nil, logger: logger)
    }
    
    internal init(options: ARTClientOptions, realtime: ARTRealtimeInternalSwift?, logger: ARTInternalLog) {
        assert(options != nil, "ARTRest: No options provided")
        
        self.options = options
        self.logger = logger
        self.queue = DispatchQueue.main
        self.userQueue = DispatchQueue.main
        
        super.init()
        
        // ARTLogVerbose(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) initialized")
    }
    
    internal convenience init(key: String) {
        self.init(options: ARTClientOptions())
    }
    
    internal convenience init(token: String) {
        self.init(options: ARTClientOptions())
    }
    
    deinit {
        // ARTLogVerbose(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) dealloc")
    }
    
    // MARK: - Public Methods (Placeholder implementations)
    
    internal func time(wrapperSDKAgents: [String: String]?, completion: @escaping ARTDateTimeCallback) {
        // Placeholder implementation - would make actual REST API call
        completion(Date(), nil)
    }
    
    internal func request(
        _ method: String,
        path: String,
        params: [String: String]?,
        body: Any?,
        headers: [String: String]?,
        wrapperSDKAgents: [String: String]?,
        callback: @escaping ARTHTTPPaginatedCallback,
        error errorPtr: inout NSError?
    ) -> Bool {
        // Placeholder implementation - would make actual HTTP request
        return true
    }
    
    internal func stats(wrapperSDKAgents: [String: String]?, completion: @escaping ARTPaginatedStatsCallback) -> Bool {
        // Placeholder implementation - would query stats API
        return true
    }
    
    internal func stats(
        _ query: Any?,
        wrapperSDKAgents: [String: String]?,
        callback: @escaping ARTPaginatedStatsCallback,
        error errorPtr: inout NSError?
    ) -> Bool {
        // Placeholder implementation - would query stats API with query parameters
        return true
    }
}
