import Foundation
#if os(iOS)
import UIKit
#endif

// swift-migration: original location ARTAuth+Private.h, line 8
public enum ARTAuthorizationState: UInt {
    case succeeded = 0  // ItemType: nil
    case failed = 1     // ItemType: NSError
    case cancelled = 2  // ItemType: nil
}

// swift-migration: original location ARTAuth.h, line 17
/// The protocol upon which the `ARTAuth` is implemented.
public protocol ARTAuthProtocol {
    /// A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error is raised if a `clientId` specified here conflicts with the `clientId` implicit in the token. Find out more about [identified clients](https://ably.com/docs/core-features/authentication#identified-clients).
    var clientId: String? { get }
    
    /// :nodoc:
    var tokenDetails: ARTTokenDetails? { get }
    
    /// Calls the `requestToken` REST API endpoint to obtain an Ably Token according to the specified `ARTTokenParams` and `ARTAuthOptions`. Both `ARTTokenParams` and `ARTAuthOptions` are optional. When omitted or `nil`, the default token parameters and authentication options for the client library are used, as specified in the `ARTClientOptions` when the client library was instantiated, or later updated with an explicit `authorize` request. Values passed in are used instead of, rather than being merged with, the default values. To understand why an Ably `ARTTokenRequest` may be issued to clients in favor of a token, see [Token Authentication explained](https://ably.com/docs/core-features/authentication/#token-authentication).
    func requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    )
    
    /// See `requestToken(_:withOptions:callback:)` for details.
    func requestToken(_ callback: @escaping ARTTokenDetailsCallback)
    
    /// Instructs the library to get a new token immediately. When using the realtime client, it upgrades the current realtime connection to use the new token, or if not connected, initiates a connection to Ably, once the new token has been obtained. Also stores any `ARTTokenParams` and `ARTAuthOptions` passed in as the new defaults, to be used for all subsequent implicit or explicit token requests. Any `ARTTokenParams` and `ARTAuthOptions` objects passed in entirely replace, as opposed to being merged with, the current client library saved values.
    func authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    )
    
    /// See `authorize(_:options:callback:)` for details.
    func authorize(_ callback: @escaping ARTTokenDetailsCallback)
    
    /// Creates and signs an Ably `ARTTokenRequest` based on the specified (or if none specified, the client library stored) `ARTTokenParams` and `ARTAuthOptions`. Note this can only be used when the API `key` value is available locally. Otherwise, the Ably `ARTTokenRequest` must be obtained from the key owner. Use this to generate an Ably `ARTTokenRequest` in order to implement an Ably Token request callback for use by other clients. Both `ARTTokenParams` and `ARTAuthOptions` are optional. When omitted or `nil`, the default token parameters and authentication options for the client library are used, as specified in the `ARTClientOptions` when the client library was instantiated, or later updated with an explicit `authorize` request. Values passed in are used instead of, rather than being merged with, the default values. To understand why an Ably `ARTTokenRequest` may be issued to clients in favor of a token, see [Token Authentication explained](https://ably.com/docs/core-features/authentication/#token-authentication).
    func createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    )
    
    /// See `createTokenRequest(_:options:callback:)` for details.
    func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void)
}

// swift-migration: original location ARTAuth.h, line 92
/// Creates Ably `ARTTokenRequest` objects and obtains Ably Tokens from Ably to subsequently issue to less trusted clients.
public class ARTAuth: NSObject, ARTAuthProtocol, Sendable {
    
    // swift-migration: original location ARTAuth.m, line 29
    internal let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTAuth.m, line 33
    internal let _internal: ARTAuthInternal
    
    // swift-migration: original location ARTAuth.m, line 32
    public init(internal internalAuth: ARTAuthInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = internalAuth
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTAuth.m, line 41
    private func internalAsync(_ use: @escaping (ARTAuthInternal) -> Void) {
        DispatchQueue.global().async {
            use(self._internal)
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 47
    public var clientId: String? {
        return _internal.clientId
    }
    
    // swift-migration: original location ARTAuth.m, line 51
    public var tokenDetails: ARTTokenDetails? {
        return _internal.tokenDetails
    }
    
    // swift-migration: original location ARTAuth.m, line 55
    public func requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        _internal.requestToken(tokenParams, withOptions: authOptions, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 61
    public func requestToken(_ callback: @escaping ARTTokenDetailsCallback) {
        _internal.requestToken(callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 65
    public func authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        _internal.authorize(tokenParams, options: authOptions, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 71
    public func authorize(_ callback: @escaping ARTTokenDetailsCallback) {
        _internal.authorize(callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 75
    public func createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    ) {
        _internal.createTokenRequest(tokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 81
    public func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        _internal.createTokenRequest(callback)
    }
}

// swift-migration: original location ARTAuth+Private.h, line 42
/// Messages related to the ARTAuth
public protocol ARTAuthDelegate: NSObjectProtocol {
    func auth(
        _ auth: ARTAuthInternal,
        didAuthorize tokenDetails: ARTTokenDetails,
        completion: @escaping (ARTAuthorizationState, ARTErrorInfo?) -> Void
    )
}

// swift-migration: original location ARTAuth+Private.h, line 16
public class ARTAuthInternal: NSObject {
    
    // swift-migration: original location ARTAuth.m, line 98
    private weak var _rest: ARTRestInternal? // weak because rest owns auth
    // swift-migration: original location ARTAuth.m, line 99
    private let _userQueue: DispatchQueue
    // swift-migration: original location ARTAuth.m, line 100
    private var _tokenParams: ARTTokenParams
    // swift-migration: original location ARTAuth.m, line 102
    private var _protocolClientId: String?
    // swift-migration: original location ARTAuth.m, line 103
    private var _authorizationsCount: Int = 0
    // swift-migration: original location ARTAuth.m, line 104
    private let _cancelationEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    // swift-migration: original location ARTAuth+Private.h, line 18
    public var clientId: String? {
        return nil // Implementation needed
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 19
    public var tokenDetails: ARTTokenDetails? = nil
    
    // swift-migration: original location ARTAuth+Private.h, line 48
    public let queue: DispatchQueue
    
    // swift-migration: original location ARTAuth.m, line 91
    internal let logger: ARTInternalLog
    
    // swift-migration: original location ARTAuth.m, line 107
    public init(_ rest: ARTRestInternal, withOptions options: ARTClientOptions, logger: ARTInternalLog) {
        self._rest = rest
        self._userQueue = rest.userQueue
        self.queue = rest.queue
        self.tokenDetails = options.tokenDetails
        self.logger = logger
        self._protocolClientId = nil
        self._cancelationEventEmitter = ARTInternalEventEmitter(queue: rest.queue)
        self._tokenParams = options.defaultTokenParams ?? ARTTokenParams(options: options)
        self._authorizationsCount = 0
        
        super.init()
        
        // swift-migration: Note - this is a simplified implementation
        // The full implementation requires all the notification observers and validation logic
        // which spans several hundred lines in the original Objective-C code
        fatalError("ARTAuth full implementation not yet complete - this is a complex 873-line file")
    }
    
    // Placeholder method implementations - these need full implementation
    public func requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        fatalError("ARTAuth method implementations not yet complete")
    }
    
    public func requestToken(_ callback: @escaping ARTTokenDetailsCallback) {
        fatalError("ARTAuth method implementations not yet complete")
    }
    
    public func authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        fatalError("ARTAuth method implementations not yet complete")
    }
    
    public func authorize(_ callback: @escaping ARTTokenDetailsCallback) {
        fatalError("ARTAuth method implementations not yet complete")
    }
    
    public func createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    ) {
        fatalError("ARTAuth method implementations not yet complete")
    }
    
    public func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        fatalError("ARTAuth method implementations not yet complete")
    }
}