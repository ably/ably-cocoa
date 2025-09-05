import Foundation

/**
 * Options for configuring channel behavior
 */
public class ARTChannelOptions: NSObject, NSCopying, @unchecked Sendable {
    
    // MARK: - Properties
    
    private var _cipher: ARTCipherParams?
    private var _frozen: Bool = false
    
    /**
     * Cipher parameters for message encryption
     */
    public var cipher: ARTCipherParams? {
        get { return _cipher }
        set {
            if isFrozen {
                fatalError("ARTChannelOptions: You can't change options after you've passed it to receiver.")
            }
            _cipher = newValue
        }
    }
    
    /**
     * Whether this options instance is frozen (immutable)
     */
    internal var frozen: Bool {
        get { return _frozen }
        set { _frozen = newValue }
    }
    
    /**
     * Check if options are frozen
     */
    public var isFrozen: Bool {
        return _frozen
    }
    
    // MARK: - Initialization
    
    /**
     * Initialize with default options
     */
    public required override init() {
        super.init()
    }
    
    /**
     * Initialize with cipher parameters
     */
    public init(cipher cipherParams: ARTCipherParamsCompatible?) {
        super.init()
        self._cipher = cipherParams?.toCipherParams()
    }
    
    /**
     * Initialize with cipher key
     */
    public init(cipherKey key: ARTCipherKeyCompatible?) {
        super.init()
        if let key = key {
            self._cipher = ["key": key].toCipherParams()
        }
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copied = type(of: self).init()
        copied._frozen = false  // Allow new instance to be mutated
        copied._cipher = _cipher
        return copied
    }
}

// MARK: - ARTCipherParamsCompatible Protocol

/**
 * Protocol for objects that can be converted to cipher parameters
 */
public protocol ARTCipherParamsCompatible {
    func toCipherParams() -> ARTCipherParams?
}

/**
 * Protocol for cipher key compatible objects
 */
public protocol ARTCipherKeyCompatible {}

// MARK: - Protocol Conformances

extension String: ARTCipherKeyCompatible {}
extension Data: ARTCipherKeyCompatible {}

extension Dictionary: ARTCipherParamsCompatible where Key == String {
    public func toCipherParams() -> ARTCipherParams? {
        // Implementation will be added when ARTCipherParams is migrated
        // For now, return placeholder
        return nil
    }
}