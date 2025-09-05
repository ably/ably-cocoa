import Foundation

#if os(iOS)
import UIKit
#endif

/**
 * Describes the possible states of authorization
 */
@frozen
public enum ARTAuthorizationState: UInt, Sendable {
    /**
     * Authorization succeeded
     */
    case succeeded = 0
    /**
     * Authorization failed
     */
    case failed = 1
    /**
     * Authorization was cancelled
     */
    case cancelled = 2
}

/// :nodoc:
public func ARTAuthorizationStateToStr(_ state: ARTAuthorizationState) -> String {
    switch state {
    case .succeeded: return "Succeeded"
    case .failed: return "Failed"
    case .cancelled: return "Cancelled"
    }
}

/**
 * An interface for authenticating with Ably
 */
public class ARTAuth: @unchecked Sendable {
    
    internal let _internal: ARTAuthInternal
    private let _dealloc: ARTQueuedDealloc
    
    // MARK: - Initialization
    
    internal init(internal: ARTAuthInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = `internal`
        self._dealloc = queuedDealloc
    }
    
    // MARK: - Public Properties
    
    /**
     * The client ID for this authentication instance
     */
    public var clientId: String? {
        return _internal.clientId
    }
    
    /**
     * The token details for this authentication instance
     */
    public var tokenDetails: ARTTokenDetails? {
        return _internal.tokenDetails
    }
    
    // MARK: - Public Methods
    
    /**
     * Request an access token from Ably using the configured authentication credentials
     */
    public func requestToken(_ tokenParams: ARTTokenParams?, 
                           withOptions authOptions: ARTAuthOptions?, 
                           callback: @escaping ARTTokenDetailsCallback) {
        _internal.requestToken(tokenParams, withOptions: authOptions, callback: callback)
    }
    
    /**
     * Request an access token from Ably using default parameters
     */
    public func requestToken(callback: @escaping ARTTokenDetailsCallback) {
        _internal.requestToken(callback: callback)
    }
    
    /**
     * Authorize and get a new token if required
     */
    public func authorize(_ tokenParams: ARTTokenParams?, 
                         options authOptions: ARTAuthOptions?, 
                         callback: @escaping ARTTokenDetailsCallback) {
        _internal.authorize(tokenParams, options: authOptions, callback: callback)
    }
    
    /**
     * Authorize using default parameters
     */
    public func authorize(callback: @escaping ARTTokenDetailsCallback) {
        _internal.authorize(callback: callback)
    }
    
    /**
     * Create a token request that can be used to obtain a token
     */
    public func createTokenRequest(_ tokenParams: ARTTokenParams?,
                                  options authOptions: ARTAuthOptions?,
                                  callback: @escaping ARTTokenRequestCallback) {
        _internal.createTokenRequest(tokenParams, options: authOptions, callback: callback)
    }
    
    /**
     * Create a token request using default parameters
     */
    public func createTokenRequest(callback: @escaping ARTTokenRequestCallback) {
        _internal.createTokenRequest(callback: callback)
    }
    
    // MARK: - Internal Helper
    
    private func internalAsync(_ use: @escaping @Sendable (ARTAuthInternal) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            use(self._internal)
        }
    }
}

// MARK: - ARTAuthInternal

/**
 * Internal authentication implementation
 */
internal class ARTAuthInternal: @unchecked Sendable {
    
    // MARK: - Properties
    
    weak var rest: ARTRestInternal?
    let userQueue: DispatchQueue
    let queue: DispatchQueue
    var tokenDetails: ARTTokenDetails?
    var options: ARTAuthOptions
    let logger: ARTInternalLog
    private var protocolClientId: String?
    private var authorizationsCount: Int = 0
    private let cancelationEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    private var tokenParams: ARTTokenParams
    private var method: ARTAuthMethod = .basic
    private var timeOffset: NSNumber?
    
    // MARK: - Initialization
    
    init(rest: ARTRestInternal, options: ARTClientOptions, logger: ARTInternalLog) {
        self.rest = rest
        self.userQueue = rest.userQueue
        self.queue = rest.queue
        self.tokenDetails = options.tokenDetails
        self.options = ARTAuthOptions(from: options)
        self.logger = logger
        self.protocolClientId = nil
        self.cancelationEventEmitter = ARTInternalEventEmitter(queue: rest.queue)
        self.tokenParams = options.defaultTokenParams ?? ARTTokenParams(options: self.options)
        self.authorizationsCount = 0
        
        validate(options)
        
        // Set up time offset observers
        setupTimeOffsetObservers()
    }
    
    deinit {
        removeTimeOffsetObserver()
    }
    
    // MARK: - Validation
    
    private func validate(_ options: ARTClientOptions) {
        logger.debug("RS:\(String(describing: rest)) validating \(options)")
        
        if options.isBasicAuth() {
            if !options.tls {
                fatalError("Basic authentication only connects over HTTPS (tls).")
            }
            // Basic
            logger.debug("RS:\(String(describing: rest)) setting up auth method Basic (anonymous)")
            method = .basic
        } else if options.tokenDetails != nil {
            // TokenDetails
            logger.debug("RS:\(String(describing: rest)) setting up auth method Token with token details")
            method = .token
        } else if options.token != nil {
            // Token
            logger.debug("RS:\(String(describing: rest)) setting up auth method Token with supplied token only")
            method = .token
            options.tokenDetails = ARTTokenDetails(token: options.token!)
        } else if options.authUrl != nil && options.authCallback != nil {
            fatalError("Incompatible authentication configuration: please specify either authCallback and authUrl.")
        } else if options.authUrl != nil {
            // Authentication url
            logger.debug("RS:\(String(describing: rest)) setting up auth method Token with authUrl")
            method = .token
        } else if options.authCallback != nil {
            // Authentication callback
            logger.debug("RS:\(String(describing: rest)) setting up auth method Token with authCallback")
            method = .token
        } else if options.key != nil {
            // Token
            logger.debug("RS:\(String(describing: rest)) setting up auth method Token with key")
            method = .token
        } else {
            fatalError("Could not setup authentication method with given options.")
        }
        
        if options.clientId == "*" {
            fatalError("Invalid clientId: cannot contain only a wildcard \"*\".")
        }
    }
    
    // MARK: - Public Interface
    
    var clientId: String? {
        var result: String?
        queue.sync {
            result = self.clientId_nosync
        }
        return result
    }
    
    private var clientId_nosync: String? {
        if let protocolClientId = protocolClientId {
            return protocolClientId
        } else if let clientId = tokenDetails?.clientId {
            return clientId
        } else {
            return options.clientId
        }
    }
    
    // MARK: - Token Management
    
    func requestToken(callback: @escaping ARTTokenDetailsCallback) {
        requestToken(tokenParams, withOptions: options, callback: callback)
    }
    
    func requestToken(_ tokenParams: ARTTokenParams?, 
                     withOptions authOptions: ARTAuthOptions?, 
                     callback: @escaping ARTTokenDetailsCallback) {
        let userCallback = callback
        let wrappedCallback: ARTTokenDetailsCallback = { tokenDetails, error in
            DispatchQueue.main.async {
                userCallback(tokenDetails, error)
            }
        }
        
        queue.async { [weak self] in
            self?._requestToken(tokenParams, withOptions: authOptions, callback: wrappedCallback)
        }
    }
    
    private func _requestToken(_ tokenParams: ARTTokenParams?, 
                              withOptions authOptions: ARTAuthOptions?, 
                              callback: @escaping ARTTokenDetailsCallback) -> ARTCancellable? {
        // Implementation will continue in the next part...
        // This is a placeholder for the complex token request logic
        callback(nil, NSError(domain: ARTAblyErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"]))
        return nil
    }
    
    // MARK: - Authorization
    
    func authorize(callback: @escaping ARTTokenDetailsCallback) {
        authorize(options.defaultTokenParams, options: options, callback: callback)
    }
    
    func authorize(_ tokenParams: ARTTokenParams?, 
                  options authOptions: ARTAuthOptions?, 
                  callback: @escaping ARTTokenDetailsCallback) {
        let userCallback = callback
        let wrappedCallback: ARTTokenDetailsCallback = { tokenDetails, error in
            DispatchQueue.main.async {
                userCallback(tokenDetails, error)
            }
        }
        
        queue.async { [weak self] in
            self?._authorize(tokenParams, options: authOptions, callback: wrappedCallback)
        }
    }
    
    private func _authorize(_ tokenParams: ARTTokenParams?, 
                           options authOptions: ARTAuthOptions?, 
                           callback: @escaping ARTTokenDetailsCallback) -> ARTCancellable? {
        // Implementation will continue in the next part...
        // This is a placeholder for the complex authorization logic
        callback(nil, NSError(domain: ARTAblyErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"]))
        return nil
    }
    
    // MARK: - Token Request Creation
    
    func createTokenRequest(callback: @escaping ARTTokenRequestCallback) {
        createTokenRequest(tokenParams, options: options, callback: callback)
    }
    
    func createTokenRequest(_ tokenParams: ARTTokenParams?,
                           options authOptions: ARTAuthOptions?,
                           callback: @escaping ARTTokenRequestCallback) {
        let userCallback = callback
        let wrappedCallback: ARTTokenRequestCallback = { tokenRequest, error in
            DispatchQueue.main.async {
                userCallback(tokenRequest, error)
            }
        }
        
        queue.async { [weak self] in
            let _ = self?._createTokenRequest(tokenParams, options: authOptions, callback: wrappedCallback)
        }
    }
    
    private func _createTokenRequest(_ tokenParams: ARTTokenParams?,
                                    options authOptions: ARTAuthOptions?,
                                    callback: @escaping ARTTokenRequestCallback) -> ARTCancellable? {
        // Implementation will continue in the next part...
        // This is a placeholder for the complex token request creation logic
        callback(nil, NSError(domain: ARTAblyErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"]))
        return nil
    }
    
    // MARK: - Time Offset Management
    
    private func setupTimeOffsetObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveCurrentLocaleDidChangeNotification(_:)),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
        
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveApplicationSignificantTimeChangeNotification(_:)),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        #else
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveApplicationSignificantTimeChangeNotification(_:)),
            name: .NSSystemClockDidChange,
            object: nil
        )
        #endif
    }
    
    private func removeTimeOffsetObserver() {
        NotificationCenter.default.removeObserver(self, name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: .NSSystemClockDidChange, object: nil)
        #endif
    }
    
    @objc private func didReceiveCurrentLocaleDidChangeNotification(_ notification: Notification) {
        logger.debug("RS:\(String(describing: rest)) NSCurrentLocaleDidChangeNotification received")
        discardTimeOffset()
    }
    
    @objc private func didReceiveApplicationSignificantTimeChangeNotification(_ notification: Notification) {
        logger.debug("RS:\(String(describing: rest)) UIApplicationSignificantTimeChangeNotification received")
        discardTimeOffset()
    }
    
    private func discardTimeOffset() {
        guard rest != nil else {
            removeTimeOffsetObserver()
            return
        }
        
        queue.sync {
            clearTimeOffset()
        }
    }
    
    private func clearTimeOffset() {
        timeOffset = nil
    }
    
    private func currentDate() -> Date {
        return Date().addingTimeInterval(timeOffset?.doubleValue ?? 0)
    }
    
    private func hasTimeOffset() -> Bool {
        return timeOffset != nil
    }
    
    private func hasTimeOffsetWithValue() -> Bool {
        return timeOffset != nil && timeOffset!.doubleValue > 0
    }
}

// MARK: - Placeholder Classes

/// Placeholder for ARTQueuedDealloc - will be migrated when needed
internal class ARTQueuedDealloc: @unchecked Sendable {
    init(rest: ARTRestInternal, queue: DispatchQueue) {
        // Placeholder implementation
    }
}

/// Placeholder for ARTRestInternal - will be migrated when needed
internal class ARTRestInternal: @unchecked Sendable {
    let userQueue: DispatchQueue = DispatchQueue.main
    let queue: DispatchQueue = DispatchQueue.global()
}

/// Placeholder for event emitter - will be migrated when needed
internal class ARTEventEmitter<EventType, DataType>: @unchecked Sendable {
    func emit(_ event: EventType?, with data: DataType?) {}
    func once(_ callback: @escaping (DataType?) -> Void) {}
}

internal class ARTInternalEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>, @unchecked Sendable {
    init(queue: DispatchQueue) {
        super.init()
    }
}