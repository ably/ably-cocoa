import Foundation

// MARK: - Type Aliases

/// :nodoc:
public typealias ARTJsonObject = [String: Any]

/// :nodoc:
public typealias ARTDeviceId = String

/// :nodoc:
public typealias ARTDeviceSecret = String

/// :nodoc:
public typealias ARTDeviceToken = Data

/// :nodoc:
public typealias ARTPushRecipient = ARTJsonObject

// MARK: - Enums

/// :nodoc:
@frozen
public enum ARTAuthentication: UInt, Sendable {
    case off = 0
    case on = 1
    case useBasic = 2
    case newToken = 3
    case tokenRetry = 4
}

/// :nodoc:
@frozen
public enum ARTAuthMethod: UInt, Sendable {
    case basic = 0
    case token = 1
}

/**
 * Describes the realtime `ARTConnection` object states.
 */
@frozen
public enum ARTRealtimeConnectionState: UInt, Sendable {
    /**
     * A connection with this state has been initialized but no connection has yet been attempted.
     */
    case initialized = 0
    /**
     * A connection attempt has been initiated. The connecting state is entered as soon as the library has completed initialization, and is reentered each time connection is re-attempted following disconnection.
     */
    case connecting = 1
    /**
     * A connection exists and is active.
     */
    case connected = 2
    /**
     * A temporary failure condition. No current connection exists because there is no network connectivity or no host is available. The disconnected state is entered if an established connection is dropped, or if a connection attempt was unsuccessful. In the disconnected state the library will periodically attempt to open a new connection (approximately every 15 seconds), anticipating that the connection will be re-established soon and thus connection and channel continuity will be possible. In this state, developers can continue to publish messages as they are automatically placed in a local queue, to be sent as soon as a connection is reestablished. Messages published by other clients while this client is disconnected will be delivered to it upon reconnection, so long as the connection was resumed within 2 minutes. After 2 minutes have elapsed, recovery is no longer possible and the connection will move to the `ARTRealtimeSuspended` state.
     */
    case disconnected = 3
    /**
     * A long term failure condition. No current connection exists because there is no network connectivity or no host is available. The suspended state is entered after a failed connection attempt if there has then been no connection for a period of two minutes. In the suspended state, the library will periodically attempt to open a new connection every 30 seconds. Developers are unable to publish messages in this state. A new connection attempt can also be triggered by an explicit call to `-[ARTConnectionProtocol connect]`. Once the connection has been re-established, channels will be automatically re-attached. The client has been disconnected for too long for them to resume from where they left off, so if it wants to catch up on messages published by other clients while it was disconnected, it needs to use the [History API](https://ably.com/docs/realtime/history).
     */
    case suspended = 4
    /**
     * An explicit request by the developer to close the connection has been sent to the Ably service. If a reply is not received from Ably within a short period of time, the connection is forcibly terminated and the connection state becomes `ARTRealtimeClosed`.
     */
    case closing = 5
    /**
     * The connection has been explicitly closed by the client. In the closed state, no reconnection attempts are made automatically by the library, and clients may not publish messages. No connection state is preserved by the service or by the library. A new connection attempt can be triggered by an explicit call to `-[ARTConnectionProtocol connect]`, which results in a new connection.
     */
    case closed = 6
    /**
     * This state is entered if the client library encounters a failure condition that it cannot recover from. This may be a fatal connection error received from the Ably service, for example an attempt to connect with an incorrect API key, or a local terminal error, for example the token in use has expired and the library does not have any way to renew it. In the failed state, no reconnection attempts are made automatically by the library, and clients may not publish messages. A new connection attempt can be triggered by an explicit call to `-[ARTConnectionProtocol connect]`.
     */
    case failed = 7
}

/// :nodoc:
public func ARTRealtimeConnectionStateToStr(_ state: ARTRealtimeConnectionState) -> String {
    switch state {
    case .initialized: return "initialized"
    case .connecting: return "connecting"
    case .connected: return "connected"
    case .disconnected: return "disconnected"
    case .suspended: return "suspended"
    case .closing: return "closing"
    case .closed: return "closed"
    case .failed: return "failed"
    }
}

/**
 * Describes the events emitted by a `ARTConnection` object. An event is either an `ARTRealtimeConnectionEventUpdate` or an `ARTRealtimeConnectionState`.
 */
@frozen
public enum ARTRealtimeConnectionEvent: UInt, Sendable {
    case initialized = 0
    case connecting = 1
    case connected = 2
    case disconnected = 3
    case suspended = 4
    case closing = 5
    case closed = 6
    case failed = 7
    /**
     * An event for changes to connection conditions for which the `ARTRealtimeConnectionState` does not change.
     */
    case update = 8
}

/// :nodoc:
public func ARTRealtimeConnectionEventToStr(_ event: ARTRealtimeConnectionEvent) -> String {
    switch event {
    case .initialized: return "initialized"
    case .connecting: return "connecting"
    case .connected: return "connected"
    case .disconnected: return "disconnected"
    case .suspended: return "suspended"
    case .closing: return "closing"
    case .closed: return "closed"
    case .failed: return "failed"
    case .update: return "update"
    }
}

/**
 * Describes the possible states of an `ARTRealtimeChannel` object.
 */
@frozen
public enum ARTRealtimeChannelState: UInt, Sendable {
    /**
     * The channel has been initialized but no attach has yet been attempted.
     */
    case initialized = 0
    /**
     * An attach has been initiated by sending a request to Ably. This is a transient state, followed either by a transition to `ARTRealtimeChannelAttached`, `ARTRealtimeChannelSuspended`, or `ARTRealtimeChannelFailed`.
     */
    case attaching = 1
    /**
     * The attach has succeeded. In the attached state a client may publish and subscribe to messages, or be present on the channel.
     */
    case attached = 2
    /**
     * A detach has been initiated on an `ARTRealtimeChannelAttached` channel by sending a request to Ably. This is a transient state, followed either by a transition to `ARTRealtimeChannelDetached` or `ARTRealtimeChannelFailed`.
     */
    case detaching = 3
    /**
     * The channel, having previously been `ARTRealtimeChannelAttached`, has been detached by the user.
     */
    case detached = 4
    /**
     * The channel, having previously been `ARTRealtimeChannelAttached`, has lost continuity, usually due to the client being disconnected from Ably for longer than two minutes. It will automatically attempt to reattach as soon as connectivity is restored.
     */
    case suspended = 5
    /**
     * An indefinite failure condition. This state is entered if a channel error has been received from the Ably service, such as an attempt to attach without the necessary access rights.
     */
    case failed = 6
}

/// :nodoc:
public func ARTRealtimeChannelStateToStr(_ state: ARTRealtimeChannelState) -> String {
    switch state {
    case .initialized: return "initialized"
    case .attaching: return "attaching"
    case .attached: return "attached"
    case .detaching: return "detaching"
    case .detached: return "detached"
    case .suspended: return "suspended"
    case .failed: return "failed"
    }
}

/**
 * Describes the events emitted by an `ARTRealtimeChannel` object. An event is either an `ARTChannelEventUpdate` or a `ARTRealtimeChannelState`.
 */
@frozen
public enum ARTChannelEvent: UInt, Sendable {
    case initialized = 0
    case attaching = 1
    case attached = 2
    case detaching = 3
    case detached = 4
    case suspended = 5
    case failed = 6
    /**
     * An event for changes to channel conditions that do not result in a change in `ARTRealtimeChannelState`.
     */
    case update = 7
}

/// :nodoc:
public func ARTChannelEventToStr(_ event: ARTChannelEvent) -> String {
    switch event {
    case .initialized: return "initialized"
    case .attaching: return "attaching"
    case .attached: return "attached"
    case .detaching: return "detaching"
    case .detached: return "detached"
    case .suspended: return "suspended"
    case .failed: return "failed"
    case .update: return "update"
    }
}

/// :nodoc:
@frozen
public enum ARTDataQueryError: Int, Sendable {
    case limit = 1
    case timestampRange = 2
    case missingRequiredFields = 3
    case invalidParameters = 4
    case deviceInactive = 5
}

/// :nodoc:
@frozen
public enum ARTRealtimeHistoryError: Int, Sendable {
    case notAttached = 3  // ARTDataQueryErrorTimestampRange + 1
}

/// :nodoc:
@frozen
public enum ARTCustomRequestError: Int, Sendable {
    case invalidMethod = 1
    case invalidBody = 2
    case invalidPath = 3
}

// MARK: - Utility Functions

/// :nodoc:
/// Decompose API key
public func decomposeKey(_ key: String) -> [String] {
    return key.components(separatedBy: ":")
}

/// :nodoc:
public func encodeBase64(_ value: String) -> String {
    return Data(value.utf8).base64EncodedString()
}

/// :nodoc:
public func decodeBase64(_ base64: String) -> String {
    guard let data = Data(base64Encoded: base64),
          let decoded = String(data: data, encoding: .utf8) else {
        return ""
    }
    return decoded
}

/// :nodoc:
public func dateToMilliseconds(_ date: Date) -> UInt64 {
    return UInt64(date.timeIntervalSince1970 * 1000)
}

/// :nodoc:
public func timeIntervalToMilliseconds(_ seconds: TimeInterval) -> UInt64 {
    return UInt64(seconds * 1000)
}

/// :nodoc:
public func millisecondsToTimeInterval(_ msecs: UInt64) -> TimeInterval {
    return TimeInterval(msecs) / 1000.0
}

/// :nodoc:
public func generateNonce() -> String {
    return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
}

// MARK: - Protocols

/// :nodoc:
public protocol ARTCancellable {
    func cancel()
}

/**
 * Contains `ARTRealtimeConnectionState` change information emitted by the `ARTConnection` object.
 */
public class ARTConnectionStateChange: @unchecked Sendable {
    
    /// :nodoc:
    public init(current: ARTRealtimeConnectionState,
                previous: ARTRealtimeConnectionState,
                event: ARTRealtimeConnectionEvent,
                reason: ARTErrorInfo?) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.retryIn = 0
    }
    
    /// :nodoc:
    public init(current: ARTRealtimeConnectionState,
                previous: ARTRealtimeConnectionState,
                event: ARTRealtimeConnectionEvent,
                reason: ARTErrorInfo?,
                retryIn: TimeInterval) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.retryIn = retryIn
    }
    
    /**
     * The new `ARTRealtimeConnectionState`.
     */
    public let current: ARTRealtimeConnectionState
    /**
     * The previous `ARTRealtimeConnectionState`. For the `ARTRealtimeConnectionEvent.ARTRealtimeConnectionEventUpdate` event, this is equal to the `current` state.
     */
    public let previous: ARTRealtimeConnectionState
    /**
     * The event that triggered this `ARTRealtimeConnectionState` change.
     */
    public let event: ARTRealtimeConnectionEvent
    
    /**
     * An `ARTErrorInfo` object containing any information relating to the transition.
     */
    public let reason: ARTErrorInfo?
    
    /**
     * Duration in milliseconds, after which the client retries a connection where applicable.
     */
    public let retryIn: TimeInterval
}

/**
 * Contains state change information emitted by an `ARTRealtimeChannel` object.
 */
public class ARTChannelStateChange: @unchecked Sendable {
    
    /// :nodoc:
    public init(current: ARTRealtimeChannelState,
                previous: ARTRealtimeChannelState,
                event: ARTChannelEvent,
                reason: ARTErrorInfo?) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.resumed = false
    }
    
    /// :nodoc:
    public init(current: ARTRealtimeChannelState,
                previous: ARTRealtimeChannelState,
                event: ARTChannelEvent,
                reason: ARTErrorInfo?,
                resumed: Bool) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.resumed = resumed
    }
    
    /**
     * The new current `ARTRealtimeChannelState`.
     */
    public let current: ARTRealtimeChannelState
    
    /**
     * The previous state. For the `ARTChannelEvent.ARTChannelEventUpdate` event, this is equal to the `current` state.
     */
    public let previous: ARTRealtimeChannelState
    
    /**
     * The event that triggered this `ARTRealtimeChannelState` change.
     */
    public let event: ARTChannelEvent
    
    /**
     * An `ARTErrorInfo` object containing any information relating to the transition.
     */
    public let reason: ARTErrorInfo?
    
    /**
     * Indicates whether message continuity on this channel is preserved, see [Nonfatal channel errors](https://ably.com/docs/realtime/channels#nonfatal-errors) for more info.
     */
    public let resumed: Bool
}

/**
 * Contains the metrics associated with a `ARTRestChannel` or `ARTRealtimeChannel`, such as the number of publishers, subscribers and connections it has.
 */
public class ARTChannelMetrics: @unchecked Sendable {
    
    /**
     * The number of realtime connections attached to the channel.
     */
    public let connections: Int
    
    /**
     * The number of realtime attachments permitted to publish messages to the channel. This requires the `publish` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelMode.ARTChannelModePublish`.
     */
    public let publishers: Int
    
    /**
     * The number of realtime attachments receiving messages on the channel. This requires the `subscribe` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelMode.ARTChannelModeSubscribe`.
     */
    public let subscribers: Int
    
    /**
     * The number of realtime connections attached to the channel with permission to enter the presence set, regardless of whether or not they have entered it. This requires the `presence` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelMode.ARTChannelModePresence`.
     */
    public let presenceConnections: Int
    
    /**
     * The number of members in the presence set of the channel.
     */
    public let presenceMembers: Int
    
    /**
     * The number of realtime attachments receiving presence messages on the channel. This requires the `subscribe` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelMode.ARTChannelModePresenceSubscribe`.
     */
    public let presenceSubscribers: Int
    
    /**
     * The number of realtime attachments permitted to publish object messages to the channel. This requires the `object-publish` capability and for a client to have specified an `ARTChannelMode` flag that includes `ARTChannelMode.ARTChannelModeObjectPublish`.
     */
    public let objectPublishers: Int
    
    /**
     * The number of realtime attachments receiving object messages on the channel. This requires the `object-subscribe` capability and for a client to have specified an `ARTChannelMode` flag that includes `ARTChannelMode.ARTChannelModeObjectSubscribe`.
     */
    public let objectSubscribers: Int
    
    /// :nodoc:
    public init(connections: Int,
                publishers: Int,
                subscribers: Int,
                presenceConnections: Int,
                presenceMembers: Int,
                presenceSubscribers: Int,
                objectPublishers: Int,
                objectSubscribers: Int) {
        self.connections = connections
        self.publishers = publishers
        self.subscribers = subscribers
        self.presenceConnections = presenceConnections
        self.presenceMembers = presenceMembers
        self.presenceSubscribers = presenceSubscribers
        self.objectPublishers = objectPublishers
        self.objectSubscribers = objectSubscribers
    }
}

/**
 * Contains the metrics of a `ARTRestChannel` or `ARTRealtimeChannel` object.
 */
public class ARTChannelOccupancy: @unchecked Sendable {
    
    /**
     * A `ARTChannelMetrics` object.
     */
    public let metrics: ARTChannelMetrics
    
    /// :nodoc:
    public init(metrics: ARTChannelMetrics) {
        self.metrics = metrics
    }
}

/**
 * Contains the status of a `ARTRestChannel` or `ARTRealtimeChannel` object such as whether it is active and its `ARTChannelOccupancy`.
 */
public class ARTChannelStatus: @unchecked Sendable {
    
    /**
     * If `true`, the channel is active, otherwise `false`.
     */
    public let active: Bool
    
    /**
     * A `ARTChannelOccupancy` object.
     */
    public let occupancy: ARTChannelOccupancy
    
    /// :nodoc:
    public init(occupancy: ARTChannelOccupancy, active: Bool) {
        self.active = active
        self.occupancy = occupancy
    }
}

/**
 * Contains the details of a `ARTRestChannel` or `ARTRealtimeChannel` object such as its ID and `ARTChannelStatus`.
 */
public class ARTChannelDetails: @unchecked Sendable {
    
    /**
     * The identifier of the channel.
     */
    public let channelId: String
    
    /**
     * A `ARTChannelStatus` object.
     */
    public let status: ARTChannelStatus
    
    /// :nodoc:
    public init(channelId: String, status: ARTChannelStatus) {
        self.channelId = channelId
        self.status = status
    }
}

/// :nodoc:
public protocol ARTJsonCompatible {
    func toJSON() throws -> [String: Any]?
    func toJSONString() -> String?
}

// MARK: - Foundation Extensions

/// :nodoc:
extension String: ARTEventIdentification {
    // ARTEventIdentification methods will be defined when migrating ARTEventEmitter
}

/// :nodoc:
extension String: ARTJsonCompatible {
    public func toJSON() throws -> [String: Any]? {
        return nil
    }
    
    public func toJSONString() -> String? {
        return self
    }
}

/// :nodoc:
extension String {
    public func shortString() -> String {
        return String(self.prefix(16))
    }
    
    public func base64Encoded() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

/// :nodoc:
extension Date {
    public static func date(withMillisecondsSince1970 msecs: UInt64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(msecs) / 1000.0)
    }
}

/// :nodoc:
extension Dictionary: ARTJsonCompatible where Key == String {
    public func toJSON() throws -> [String: Any]? {
        return self as? [String: Any]
    }
    
    public func toJSONString() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

/// :nodoc:
extension Dictionary where Key == String, Value == String {
    public var asURLQueryItems: [URLQueryItem] {
        return self.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}

/// :nodoc:
extension Array {
    public mutating func enqueue(_ object: Element) {
        self.append(object)
    }
    
    public mutating func dequeue() -> Element? {
        return self.isEmpty ? nil : self.removeFirst()
    }
    
    public func peek() -> Element? {
        return self.first
    }
}

/// :nodoc:
extension URLSessionTask: ARTCancellable {
    // Already conforms to ARTCancellable via cancel() method
}

/// :nodoc:
public typealias NSStringDictionary = [String: String]

// MARK: - Completion Handler Type Aliases

/// :nodoc:
public typealias ARTCallback = (ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTResultCallback = (Any?, Error?) -> Void

/// :nodoc:
public typealias ARTDateTimeCallback = (Date?, Error?) -> Void

/// :nodoc:
public typealias ARTMessageCallback = (ARTMessage) -> Void

/// :nodoc:
public typealias ARTChannelStateCallback = (ARTChannelStateChange) -> Void

/// :nodoc:
public typealias ARTConnectionStateCallback = (ARTConnectionStateChange) -> Void

/// :nodoc:
public typealias ARTPresenceMessageCallback = (ARTPresenceMessage) -> Void

/// :nodoc:
public typealias ARTPresenceMessageErrorCallback = (ARTPresenceMessage, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPresenceMessagesCallback = ([ARTPresenceMessage]?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTAnnotationCallback = (ARTAnnotation) -> Void

/// :nodoc:
public typealias ARTAnnotationErrorCallback = (ARTAnnotation, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedAnnotationsCallback = (ARTPaginatedResult<ARTAnnotation>?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTChannelDetailsCallback = (ARTChannelDetails?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTStatusCallback = (ARTStatus) -> Void

/// :nodoc:
public typealias ARTURLRequestCallback = (HTTPURLResponse?, Data?, Error?) -> Void

/// :nodoc:
public typealias ARTTokenDetailsCallback = @Sendable (ARTTokenDetails?, Error?) -> Void

/// :nodoc:
public typealias ARTTokenRequestCallback = @Sendable (ARTTokenRequest?, Error?) -> Void

/// :nodoc:
public typealias ARTTokenDetailsCompatibleCallback = (ARTTokenDetailsCompatible?, Error?) -> Void

/// :nodoc:
public typealias ARTAuthCallback = (ARTTokenParams, @escaping ARTTokenDetailsCompatibleCallback) -> Void

/// :nodoc:
public typealias ARTHTTPPaginatedCallback = (ARTHTTPPaginatedResponse?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedStatsCallback = (ARTPaginatedResult<ARTStats>?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedPresenceCallback = (ARTPaginatedResult<ARTPresenceMessage>?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedPushChannelCallback = (ARTPaginatedResult<ARTPushChannelSubscription>?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedMessagesCallback = (ARTPaginatedResult<ARTMessage>?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedDeviceDetailsCallback = (ARTPaginatedResult<ARTDeviceDetails>?, ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTPaginatedTextCallback = (ARTPaginatedResult<String>?, ARTErrorInfo?) -> Void

/**
 * :nodoc:
 *
 * Wraps the given callback in an ARTCancellable, offering the following protections:
 *
 * 1) If the cancel method is called on the returned instance then the callback will not be invoked.
 * 2) The callback will only ever be invoked once.
 *
 * To make use of these benefits the caller needs to use the returned wrapper to invoke the callback. The wrapper will only work for as long as the returned instance remains allocated (i.e. has a strong reference to it somewhere).
 */
public func artCancellableFromCallback(_ callback: @escaping ARTResultCallback) -> (ARTCancellable, ARTResultCallback) {
    let cancellable = ARTCancellableCallback(callback: callback)
    return (cancellable, cancellable.wrappedCallback)
}

/// :nodoc:
private class ARTCancellableCallback: ARTCancellable {
    private let callback: ARTResultCallback
    private var isCancelled = false
    private var hasBeenCalled = false
    private let lock = NSLock()
    
    init(callback: @escaping ARTResultCallback) {
        self.callback = callback
    }
    
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
    }
    
    lazy var wrappedCallback: ARTResultCallback = { [weak self] result, error in
        guard let self = self else { return }
        
        self.lock.lock()
        defer { self.lock.unlock() }
        
        guard !self.isCancelled && !self.hasBeenCalled else { return }
        self.hasBeenCalled = true
        
        self.callback(result, error)
    }
}

// MARK: - Forward Declarations
// These types will be defined in later phases of the migration

public protocol ARTEventIdentification {}
public protocol ARTTokenDetailsCompatible {}

// Placeholder classes that will be migrated in later phases
public class ARTErrorInfo: @unchecked Sendable {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    public static func create(from error: Error) -> ARTErrorInfo {
        return ARTErrorInfo(code: (error as NSError).code, message: error.localizedDescription)
    }
    
    public static func create(withCode code: Int, message: String) -> ARTErrorInfo {
        return ARTErrorInfo(code: code, message: message)
    }
}



/// Placeholder for ARTTokenParams - will be migrated when needed
public class ARTTokenParams: @unchecked Sendable {
    public var capability: String?
    public var clientId: String?
    public var timestamp: Date?
    public var ttl: TimeInterval?
    public var nonce: String?
    
    public init(options: ARTAuthOptions) {
        // Initialize from auth options - placeholder implementation
    }
    
    public init() {
        // Default initializer
    }
}

/// Placeholder for ARTTokenRequest - will be migrated when needed
public class ARTTokenRequest: @unchecked Sendable {
    public var keyName: String?
    public var ttl: TimeInterval?
    public var capability: String?
    public var clientId: String?
    public var timestamp: Date?
    public var nonce: String?
    public var mac: String?
    
    public init() {}
}

/// Placeholder for ARTTokenDetails - will be migrated when needed
public class ARTTokenDetails: @unchecked Sendable {
    public var token: String?
    public var clientId: String?
    public var expires: Date?
    public var issued: Date?
    public var capability: String?
    
    public init(token: String) {
        self.token = token
    }
    
    public init() {}
}

/// Placeholder for ARTAuthOptions - will be migrated when needed
public class ARTAuthOptions: @unchecked Sendable {
    public var key: String?
    public var tokenDetails: ARTTokenDetails?
    public var authCallback: ARTAuthCallback?
    public var authUrl: URL?
    public var authHeaders: [String: String]?
    public var authMethod: String = "GET"
    public var authParams: [String: String]?
    public var useTokenAuth: Bool = false
    public var queryTime: Bool = false
    public var clientId: String?
    public var defaultTokenParams: ARTTokenParams?
    
    public init(from options: ARTClientOptions) {
        // Initialize from client options - placeholder implementation
    }
    
    public init() {
        // Default initializer
    }
}

/// Placeholder for ARTClientOptions - will be migrated when needed
public class ARTClientOptions: @unchecked Sendable {
    public var tokenDetails: ARTTokenDetails?
    public var token: String?
    public var key: String?
    public var tls: Bool = true
    public var clientId: String?
    public var authUrl: URL?
    public var authCallback: ARTAuthCallback?
    public var defaultTokenParams: ARTTokenParams?
    
    public func isBasicAuth() -> Bool {
        return key != nil && tokenDetails == nil && token == nil && authUrl == nil && authCallback == nil
    }
}
public class ARTHTTPPaginatedResponse: @unchecked Sendable {}
public class ARTPaginatedResult<ItemType>: @unchecked Sendable {}
public class ARTStats: @unchecked Sendable {}
public class ARTPushChannelSubscription: @unchecked Sendable {}
public class ARTDeviceDetails: @unchecked Sendable {}

public class ARTLocalDevice: @unchecked Sendable {}
public class ARTDeviceIdentityTokenDetails: @unchecked Sendable {}
public class ARTDevicePushDetails: @unchecked Sendable {}