import Foundation

// MARK: - Type definitions from ARTTypes.h

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

/// :nodoc:
public enum ARTAuthentication: UInt, Sendable {
    case off = 0
    case on = 1
    case useBasic = 2
    case newToken = 3
    case tokenRetry = 4
}

/// :nodoc:
public enum ARTAuthMethod: UInt, Sendable {
    case basic = 0
    case token = 1
}

/// :nodoc:
public enum ARTDataQueryError: Int, Sendable {
    case limit = 1
    case timestampRange = 2
    case missingRequiredFields = 3
    case invalidParameters = 4
    case deviceInactive = 5
}

/// :nodoc:
public enum ARTRealtimeHistoryError: Int, Sendable {
    case notAttached = 3 // ARTDataQueryErrorTimestampRange + 1
}

/// :nodoc:
public enum ARTCustomRequestError: Int, Sendable {
    case invalidMethod = 1
    case invalidBody = 2
    case invalidPath = 3
}

/// :nodoc:
public enum ARTChannelEvent: UInt, Sendable {
    case initialized = 0
    case attaching = 1
    case attached = 2  
    case detaching = 3
    case detached = 4
    case suspended = 5
    case failed = 6
    case update = 7
}

// MARK: Global helper functions

// swift-migration: original location ARTTypes.m, line 7
func decomposeKey(_ key: String) -> [String] {
    return key.components(separatedBy: ":")
}

// swift-migration: original location ARTTypes.m, line 11
func encodeBase64(_ value: String) -> String {
    return Data(value.utf8).base64EncodedString()
}

// swift-migration: original location ARTTypes.m, line 15
func decodeBase64(_ base64: String) -> String? {
    guard let data = Data(base64Encoded: base64) else { return nil }
    return String(data: data, encoding: .utf8)
}

// swift-migration: original location ARTTypes.m, line 20
func dateToMilliseconds(_ date: Date) -> UInt64 {
    return UInt64(date.timeIntervalSince1970 * 1000)
}

// swift-migration: original location ARTTypes.m, line 24
func timeIntervalToMilliseconds(_ seconds: TimeInterval) -> UInt64 {
    return UInt64(seconds * 1000)
}

// swift-migration: original location ARTTypes.m, line 28 (already defined in MigrationPlaceholders.swift but moved here)
func millisecondsToTimeInterval(_ msecs: UInt64) -> TimeInterval {
    return TimeInterval(msecs) / 1000.0
}

// swift-migration: original location ARTTypes.m, line 32
func generateNonce() -> String {
    // Generate two random numbers up to 8 digits long and concatenate them to produce a 16 digit random number
    let r1 = UInt32.random(in: 0..<100000000)
    let r2 = UInt32.random(in: 0..<100000000)
    return String(format: "%08u%08u", r1, r2)
}

// MARK: - ARTConnectionStateChange

// swift-migration: original location ARTTypes.m, line 41
public class ARTConnectionStateChange: NSObject {
    public let current: ARTRealtimeConnectionState
    public let previous: ARTRealtimeConnectionState
    public let event: ARTRealtimeConnectionEvent
    public let reason: ARTErrorInfo?
    public private(set) var retryIn: TimeInterval
    public let retryAttempt: ARTRetryAttempt?

    // swift-migration: original location ARTTypes.m, line 43
    public init(current: ARTRealtimeConnectionState, previous: ARTRealtimeConnectionState, event: ARTRealtimeConnectionEvent, reason: ARTErrorInfo?) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.retryIn = 0
        self.retryAttempt = nil
        super.init()
    }

    // swift-migration: original location ARTTypes.m, line 47
    public init(current: ARTRealtimeConnectionState, previous: ARTRealtimeConnectionState, event: ARTRealtimeConnectionEvent, reason: ARTErrorInfo?, retryIn: TimeInterval) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.retryIn = retryIn
        self.retryAttempt = nil
        super.init()
    }

    // swift-migration: original location ARTTypes.m, line 51
    public init(current: ARTRealtimeConnectionState, previous: ARTRealtimeConnectionState, event: ARTRealtimeConnectionEvent, reason: ARTErrorInfo?, retryIn: TimeInterval, retryAttempt: ARTRetryAttempt?) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.retryIn = retryIn
        self.retryAttempt = retryAttempt
        super.init()
    }

    // swift-migration: original location ARTTypes.m, line 64
    public override var description: String {
        return "\(super.description) - \n\t event: \(ARTRealtimeConnectionEventToStr(event)); \n\t current: \(ARTRealtimeConnectionStateToStr(current)); \n\t previous: \(ARTRealtimeConnectionStateToStr(previous)); \n\t reason: \(reason?.description ?? "nil"); \n\t retryIn: \(retryIn); \n\t retryAttempt: \(String(describing: retryAttempt)); \n"
    }

    // swift-migration: original location ARTTypes.m, line 68
    public func setRetryIn(_ retryIn: TimeInterval) {
        self.retryIn = retryIn
    }
}

// swift-migration: original location ARTTypes.m, line 74
public func ARTRealtimeConnectionStateToStr(_ state: ARTRealtimeConnectionState) -> String {
    switch state {
    case .initialized:
        return "Initialized" // 0
    case .connecting:
        return "Connecting" // 1
    case .connected:
        return "Connected" // 2
    case .disconnected:
        return "Disconnected" // 3
    case .suspended:
        return "Suspended" // 4
    case .closing:
        return "Closing" // 5
    case .closed:
        return "Closed" // 6
    case .failed:
        return "Failed" // 7
    }
}

// swift-migration: original location ARTTypes.m, line 95
public func ARTRealtimeConnectionEventToStr(_ event: ARTRealtimeConnectionEvent) -> String {
    switch event {
    case .initialized:
        return "Initialized" // 0
    case .connecting:
        return "Connecting" // 1
    case .connected:
        return "Connected" // 2
    case .disconnected:
        return "Disconnected" // 3
    case .suspended:
        return "Suspended" // 4
    case .closing:
        return "Closing" // 5
    case .closed:
        return "Closed" // 6
    case .failed:
        return "Failed" // 7
    case .update:
        return "Update" // 8
    }
}

// MARK: - ARTChannelStateChange

// swift-migration: original location ARTTypes.m, line 120
public class ARTChannelStateChange: NSObject {
    public let current: ARTRealtimeChannelState
    public let previous: ARTRealtimeChannelState
    public let event: ARTChannelEvent
    public let reason: ARTErrorInfo?
    public let resumed: Bool
    public let retryAttempt: ARTRetryAttempt?

    // swift-migration: original location ARTTypes.m, line 122
    public init(current: ARTRealtimeChannelState, previous: ARTRealtimeChannelState, event: ARTChannelEvent, reason: ARTErrorInfo?) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.resumed = false
        self.retryAttempt = nil
        super.init()
    }

    // swift-migration: original location ARTTypes.m, line 126
    public init(current: ARTRealtimeChannelState, previous: ARTRealtimeChannelState, event: ARTChannelEvent, reason: ARTErrorInfo?, resumed: Bool) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.resumed = resumed
        self.retryAttempt = nil
        super.init()
    }

    // swift-migration: original location ARTTypes.m, line 130
    public init(current: ARTRealtimeChannelState, previous: ARTRealtimeChannelState, event: ARTChannelEvent, reason: ARTErrorInfo?, resumed: Bool, retryAttempt: ARTRetryAttempt?) {
        self.current = current
        self.previous = previous
        self.event = event
        self.reason = reason
        self.resumed = resumed
        self.retryAttempt = retryAttempt
        super.init()
    }

    // swift-migration: original location ARTTypes.m, line 143
    public override var description: String {
        return "\(super.description) - \n\t current: \(ARTRealtimeChannelStateToStr(current)); \n\t previous: \(ARTRealtimeChannelStateToStr(previous)); \n\t event: \(ARTChannelEventToStr(event)); \n\t reason: \(reason?.description ?? "nil"); \n\t resumed: \(resumed); \n\t retryAttempt: \(String(describing: retryAttempt)); \n"
    }
}

// MARK: - ARTChannelMetrics

// swift-migration: original location ARTTypes.m, line 151
public class ARTChannelMetrics: NSObject {
    public let connections: Int
    public let publishers: Int
    public let subscribers: Int
    public let presenceConnections: Int
    public let presenceMembers: Int
    public let presenceSubscribers: Int
    public let objectPublishers: Int
    public let objectSubscribers: Int

    // swift-migration: original location ARTTypes.m, line 153
    public init(connections: Int, publishers: Int, subscribers: Int, presenceConnections: Int, presenceMembers: Int, presenceSubscribers: Int, objectPublishers: Int, objectSubscribers: Int) {
        self.connections = connections
        self.publishers = publishers
        self.subscribers = subscribers
        self.presenceConnections = presenceConnections
        self.presenceMembers = presenceMembers
        self.presenceSubscribers = presenceSubscribers
        self.objectPublishers = objectPublishers
        self.objectSubscribers = objectSubscribers
        super.init()
    }
}

// MARK: - ARTChannelOccupancy

// swift-migration: original location ARTTypes.m, line 179
public class ARTChannelOccupancy: NSObject {
    public let metrics: ARTChannelMetrics

    // swift-migration: original location ARTTypes.m, line 181
    public init(metrics: ARTChannelMetrics) {
        self.metrics = metrics
        super.init()
    }
}

// MARK: - ARTChannelStatus

// swift-migration: original location ARTTypes.m, line 192
public class ARTChannelStatus: NSObject {
    public let occupancy: ARTChannelOccupancy
    public let active: Bool

    // swift-migration: original location ARTTypes.m, line 194
    public init(occupancy: ARTChannelOccupancy, active: Bool) {
        self.occupancy = occupancy
        self.active = active
        super.init()
    }
}

// MARK: - ARTChannelDetails

// swift-migration: original location ARTTypes.m, line 206 (overriding placeholder)
public class ARTChannelDetails: NSObject {
    public let channelId: String
    public let status: ARTChannelStatus

    // swift-migration: original location ARTTypes.m, line 208
    public init(channelId: String, status: ARTChannelStatus) {
        self.channelId = channelId
        self.status = status
        super.init()
    }
}

// MARK: - ARTEventIdentification

// swift-migration: original location ARTTypes.m, line 220
extension String: ARTEventIdentification {
    public func identification() -> String {
        return self
    }
}

// MARK: - ARTJsonCompatible

// swift-migration: original location ARTTypes.m, line 230
extension String: ARTJsonCompatible {
    
    // swift-migration: original location ARTTypes.m, line 232
    public func toJSON() throws -> [String: Any]? {
        guard let data = self.data(using: .utf8) else {
            throw NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "Failed to encode string to UTF-8"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let dictionary = json as? [String: Any] else {
            throw NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: "expected JSON object, got \(type(of: json))"])
        }
        
        return dictionary
    }

    // swift-migration: original location ARTTypes.m, line 251
    public func toJSONString() -> String? {
        return self
    }
}

// swift-migration: original location ARTTypes.m, line 257
extension Dictionary: ARTJsonCompatible where Key == String, Value == Any {
    
    // swift-migration: original location ARTTypes.m, line 259
    public func toJSON() throws -> [String: Any]? {
        return self
    }

    // swift-migration: original location ARTTypes.m, line 266
    public func toJSONString() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
}

// swift-migration: original location ARTTypes.m, line 278
extension URL {
    // Note: Can't override description in extension, this is for implementation reference only
    public var art_description: String {
        return absoluteString
    }
}

// swift-migration: original location ARTTypes.m, line 286
public func ARTRealtimeChannelStateToStr(_ state: ARTRealtimeChannelState) -> String {
    switch state {
    case .initialized:
        return "Initialized" // 0
    case .attaching:
        return "Attaching" // 1
    case .attached:
        return "Attached" // 2
    case .detaching:
        return "Detaching" // 3
    case .detached:
        return "Detached" // 4
    case .suspended:
        return "Suspended" // 5
    case .failed:
        return "Failed" // 6
    }
}

// swift-migration: original location ARTTypes.m, line 305
public func ARTChannelEventToStr(_ event: ARTChannelEvent) -> String {
    switch event {
    case .initialized:
        return "Initialized" // 0
    case .attaching:
        return "Attaching" // 1
    case .attached:
        return "Attached" // 2
    case .detaching:
        return "Detaching" // 3
    case .detached:
        return "Detached" // 4
    case .suspended:
        return "Suspended" // 5
    case .failed:
        return "Failed" // 6
    case .update:
        return "Update" // 7
    }
}

// MARK: - NSDictionary (ARTURLQueryItemAdditions)

// swift-migration: original location ARTTypes.m, line 326
extension Dictionary where Key == String, Value == Any {
    // swift-migration: original location ARTTypes.m, line 328
    public func art_asURLQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        for (key, value) in self {
            if let stringValue = value as? String {
                items.append(URLQueryItem(name: key, value: stringValue))
            }
        }
        return items
    }
}

// MARK: - Array (ARTQueueAdditions)

// swift-migration: original location ARTTypes.m, line 341
// Note: Swift equivalent using Array methods rather than NSMutableArray category
extension Array {
    // swift-migration: original location ARTTypes.m, line 343
    public mutating func art_enqueue(_ object: Element) {
        append(object)
    }
    
    // swift-migration: original location ARTTypes.m, line 347
    public mutating func art_dequeue() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    // swift-migration: original location ARTTypes.m, line 355
    public func art_peek() -> Element? {
        return first
    }
}

// MARK: - NSString (ARTUtilities)

// swift-migration: original location ARTTypes.m, line 363
extension String {
    public var art_shortString: String {
        return self
    }
}

// swift-migration: original location ARTTypes.m, line 371
extension String {
    public var art_base64Encoded: String {
        return encodeBase64(self)
    }
}

// MARK: - NSDate (ARTUtilities)

// swift-migration: original location ARTTypes.m, line 379
extension Date {
    // swift-migration: original location ARTTypes.m, line 381
    public static func art_date(withMillisecondsSince1970 msecs: UInt64) -> Date {
        return Date(timeIntervalSince1970: millisecondsToTimeInterval(msecs))
    }
}

// ARTCancellableFromCallback and related functions - implementing core cancellation functionality

// swift-migration: original location ARTTypes.m, line 387
internal class ARTCancellableFromCallback: NSObject, ARTCancellable {
    private let lock = NSObject()
    private var callback: ARTResultCallback?
    public private(set) var wrapper: ARTResultCallback!

    @available(*, unavailable, message: "Use init(callback:) instead")
    public override init() {
        fatalError("Use init(callback:) instead")
    }

    // swift-migration: original location ARTTypes.m, line 404
    public init(callback: @escaping ARTResultCallback) {
        // Initialize callback first
        self.callback = callback
        
        // Call super.init()
        super.init()
        
        // Create wrapper with weak reference pattern after init
        weak var weakSelf = self
        self.wrapper = { result, error in
            weakSelf?.invokeWithResult(result, error: error)
        }
    }

    // swift-migration: original location ARTTypes.m, line 426
    public func cancel() {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        callback = nil
    }

    // swift-migration: original location ARTTypes.m, line 432
    private func invokeWithResult(_ result: Any?, error: Error?) {
        var callbackToInvoke: ARTResultCallback?
        
        objc_sync_enter(lock)
        callbackToInvoke = callback
        callback = nil
        objc_sync_exit(lock)
        
        if let callbackToInvoke = callbackToInvoke {
            callbackToInvoke(result, error)
        }
    }
}

// swift-migration: original location ARTTypes.m, line 447
extension NSObject {
    
    // swift-migration: original location ARTTypes.m, line 449
    public func art_archive(withLogger logger: ARTInternalLog?) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            return data
        } catch {
            if let logger = logger {
                ARTLogError(logger, "Archive failed: \(error)")
            }
            return nil
        }
    }

    // swift-migration: original location ARTTypes.m, line 458
    public static func art_unarchive(fromData data: Data, withLogger logger: ARTInternalLog?) -> Any? {
        do {
            let result = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSDictionary.self, NSObject.self], from: data)
            return result
        } catch {
            if let logger = logger {
                ARTLogError(logger, "Unarchive failed: \(error)")
            }
            return nil
        }
    }
}

// swift-migration: original location ARTTypes.m, line 470
public func artCancellableFromCallback(_ callback: @escaping ARTResultCallback) -> (cancellable: ARTCancellable, wrapper: ARTResultCallback) {
    let cancellable = ARTCancellableFromCallback(callback: callback)
    return (cancellable, cancellable.wrapper)
}

// Placeholder protocols and types that need to be defined

// swift-migration: ARTEventIdentification protocol defined in ARTEventEmitter.swift

// Additional typedefs from ARTTypes.h that were missing

/// :nodoc:
public typealias NSStringDictionary = [String: String]

// Callback type definitions from ARTTypes.h (removing duplicates from placeholders)
/// :nodoc:
public typealias ARTCallback = (ARTErrorInfo?) -> Void

/// :nodoc:
public typealias ARTResultCallback = (Any?, Error?) -> Void

/// :nodoc:  
public typealias ARTDateTimeCallback = (Date?, Error?) -> Void

// swift-migration: original location ARTTypes.h, line 502
/// :nodoc:
public typealias ARTMessageCallback = (ARTMessage) -> Void

// swift-migration: original location ARTTypes.h, line 505
/// :nodoc:
public typealias ARTChannelStateCallback = (ARTChannelStateChange) -> Void

// swift-migration: original location ARTTypes.h, line 508
/// :nodoc:
public typealias ARTConnectionStateCallback = (ARTConnectionStateChange) -> Void

// swift-migration: original location ARTTypes.h, line 511
/// :nodoc:
public typealias ARTPresenceMessageCallback = (ARTPresenceMessage) -> Void

// swift-migration: original location ARTTypes.h, line 514
/// :nodoc:
public typealias ARTPresenceMessageErrorCallback = (ARTPresenceMessage, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 517
/// :nodoc:
public typealias ARTPresenceMessagesCallback = ([ARTPresenceMessage]?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 520
/// :nodoc:
public typealias ARTAnnotationCallback = (ARTAnnotation) -> Void

// swift-migration: original location ARTTypes.h, line 523
/// :nodoc:
public typealias ARTAnnotationErrorCallback = (ARTAnnotation, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 526
/// :nodoc:
public typealias ARTPaginatedAnnotationsCallback = (ARTPaginatedResult<ARTAnnotation>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 529
/// :nodoc:
public typealias ARTChannelDetailsCallback = (ARTChannelDetails?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 532
/// :nodoc:
public typealias ARTStatusCallback = (ARTStatus) -> Void

// swift-migration: original location ARTTypes.h, line 535
/// :nodoc:
public typealias ARTURLRequestCallback = (HTTPURLResponse?, Data?, Error?) -> Void

// swift-migration: original location ARTTypes.h, line 538
/// :nodoc:
public typealias ARTTokenDetailsCallback = @Sendable (ARTTokenDetails?, Error?) -> Void

// swift-migration: original location ARTTypes.h, line 541
/// :nodoc:
public typealias ARTTokenDetailsCompatibleCallback = @Sendable (ARTTokenDetailsCompatible?, Error?) -> Void

// swift-migration: original location ARTTypes.h, line 544
/// :nodoc:
public typealias ARTAuthCallback = @Sendable (ARTTokenParams?, @escaping ARTTokenDetailsCompatibleCallback) -> Void

// swift-migration: original location ARTTypes.h, line 547
/// :nodoc:
public typealias ARTHTTPPaginatedCallback = (ARTHTTPPaginatedResponse?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 550
/// :nodoc:
public typealias ARTPaginatedStatsCallback = (ARTPaginatedResult<ARTStats>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 553
/// :nodoc:
public typealias ARTPaginatedPresenceCallback = (ARTPaginatedResult<ARTPresenceMessage>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 556
/// :nodoc:
public typealias ARTPaginatedPushChannelCallback = (ARTPaginatedResult<ARTPushChannelSubscription>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 559
/// :nodoc:
public typealias ARTPaginatedMessagesCallback = (ARTPaginatedResult<ARTMessage>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 562
/// :nodoc:
public typealias ARTPaginatedDeviceDetailsCallback = (ARTPaginatedResult<ARTDeviceDetails>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTTypes.h, line 565
/// :nodoc:
public typealias ARTPaginatedTextCallback = (ARTPaginatedResult<String>?, ARTErrorInfo?) -> Void
