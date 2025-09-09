import Foundation

/**
 * Describes the possible flags used to configure client capabilities, using `ARTChannelOptions`.
 */
// swift-migration: original location ARTRealtimeChannelOptions.h, line 9
public struct ARTChannelMode: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /**
     * The client can enter the presence set.
     */
    public static let presence = ARTChannelMode(rawValue: 1 << 16)
    /**
     * The client can publish messages.
     */
    public static let publish = ARTChannelMode(rawValue: 1 << 17)
    /**
     * The client can subscribe to messages.
     */
    public static let subscribe = ARTChannelMode(rawValue: 1 << 18)
    /**
     * The client can receive presence messages.
     */
    public static let presenceSubscribe = ARTChannelMode(rawValue: 1 << 19)
    /**
     * The client can publish annotations to messages.
     */
    public static let annotationPublish = ARTChannelMode(rawValue: 1 << 21)
    /**
     * The client can receive annotations for messages.
     */
    public static let annotationSubscribe = ARTChannelMode(rawValue: 1 << 22)
    /**
     * The client can receive object messages.
     */
    public static let objectSubscribe = ARTChannelMode(rawValue: 1 << 24)
    /**
     * The client can publish object messages.
     */
    public static let objectPublish = ARTChannelMode(rawValue: 1 << 25)
}

/**
 * Passes additional properties to an `ARTRealtimeChannel` object, such as encryption, an `ARTChannelMode` and channel parameters.
 */
// swift-migration: original location ARTRealtimeChannelOptions.h, line 49 and ARTRealtimeChannelOptions.m, line 4
public class ARTRealtimeChannelOptions: ARTChannelOptions {
    
    // swift-migration: original location ARTRealtimeChannelOptions.m, line 5
    private var _params: NSStringDictionary?
    // swift-migration: original location ARTRealtimeChannelOptions.m, line 6
    private var _modes: ARTChannelMode = []
    // swift-migration: original location ARTRealtimeChannelOptions.m, line 7
    private var _attachOnSubscribe: Bool = true
    
    /**
     * [Channel Parameters](https://ably.com/docs/realtime/channels/channel-parameters/overview) that configure the behavior of the channel.
     */
    // swift-migration: original location ARTRealtimeChannelOptions.h, line 54 and ARTRealtimeChannelOptions.m, line 34
    public var params: NSStringDictionary? {
        get {
            return _params
        }
        set {
            if isFrozen {
                fatalError("\(type(of: self)): You can't change options after you've passed it to receiver.")
            }
            _params = newValue
        }
    }
    
    /**
     * An array of `ARTChannelMode` objects.
     */
    // swift-migration: original location ARTRealtimeChannelOptions.h, line 59 and ARTRealtimeChannelOptions.m, line 47
    public var modes: ARTChannelMode {
        get {
            return _modes
        }
        set {
            if isFrozen {
                fatalError("\(type(of: self)): You can't change options after you've passed it to receiver.")
            }
            _modes = newValue
        }
    }
    
    /**
     * A boolean which determines whether calling `subscribe` on a `ARTRealtimeChannel` or `ARTRealtimePresense` object should trigger an implicit attach (for realtime client libraries only). Defaults to true.
     */
    // swift-migration: original location ARTRealtimeChannelOptions.h, line 64 and ARTRealtimeChannelOptions.m, line 60
    public var attachOnSubscribe: Bool {
        get {
            return _attachOnSubscribe
        }
        set {
            if isFrozen {
                fatalError("\(type(of: self)): You can't change options after you've passed it to receiver.")
            }
            _attachOnSubscribe = newValue
        }
    }
    
    // swift-migration: original location ARTRealtimeChannelOptions.m, line 10
    public required init() {
        _attachOnSubscribe = true
        super.init()
    }
    
    // swift-migration: original location ARTRealtimeChannelOptions.m, line 17
    public override init(cipher cipherParams: ARTCipherParamsCompatible?) {
        _attachOnSubscribe = true
        super.init(cipher: cipherParams)
    }
    
    // swift-migration: original location ARTRealtimeChannelOptions.m, line 24
    public override func copy(with zone: NSZone?) -> Any {
        let copied = super.copy(with: zone) as! ARTRealtimeChannelOptions
        copied._params = _params
        copied._modes = _modes
        copied._attachOnSubscribe = _attachOnSubscribe
        return copied
    }
}