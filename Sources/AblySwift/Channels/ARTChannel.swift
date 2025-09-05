import Foundation

/**
 * Base class for Ably channels, providing common functionality for REST and Realtime channels
 */
open class ARTChannel: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    /**
     * Channel name
     */
    public let name: String
    
    /**
     * Logger instance
     */
    public let logger: ARTInternalLog
    
    /**
     * Data encoder for message encryption/decryption
     */
    internal var dataEncoder: ARTDataEncoder
    
    /**
     * Dispatch queue for thread safety
     */
    internal let queue: DispatchQueue
    
    /**
     * Channel options
     */
    private var _options: ARTChannelOptions
    
    // MARK: - Initialization
    
    /**
     * Initialize channel with name, options, and dependencies
     */
    internal init(name: String, options: ARTChannelOptions, queue: DispatchQueue, logger: ARTInternalLog) throws {
        self.name = name
        self.logger = logger
        self.queue = queue
        self._options = options.copy() as! ARTChannelOptions
        self._options.frozen = true
        
        // Initialize data encoder with cipher parameters
        do {
            self.dataEncoder = try ARTDataEncoder(cipherParams: self._options.cipher, logger: logger)
        } catch {
            logger.warn("creating ARTDataEncoder: \(error)")
            self.dataEncoder = try ARTDataEncoder(cipherParams: nil, logger: logger)
        }
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    /**
     * Get channel options (thread-safe)
     */
    public var options: ARTChannelOptions {
        var result: ARTChannelOptions!
        queue.sync {
            result = self._options
        }
        return result
    }
    
    /**
     * Set channel options (thread-safe)
     */
    public func setOptions(_ options: ARTChannelOptions?) {
        queue.sync {
            guard let options = options else { return }
            self._options = options.copy() as! ARTChannelOptions
            self._options.frozen = true
            self.recreateDataEncoder(with: options.cipher)
        }
    }
    
    // MARK: - Internal Methods
    
    /**
     * Recreate data encoder with new cipher parameters
     */
    internal func recreateDataEncoder(with cipher: ARTCipherParams?) {
        do {
            self.dataEncoder = try ARTDataEncoder(cipherParams: cipher, logger: logger)
        } catch {
            logger.warn("creating ARTDataEncoder: \(error)")
            do {
                self.dataEncoder = try ARTDataEncoder(cipherParams: nil, logger: logger)
            } catch {
                // This should never happen with nil cipher params, but handle it
                logger.error("Failed to create ARTDataEncoder even with nil cipher: \(error)")
            }
        }
    }
    
    /**
     * Encode message if needed
     */
    internal func encodeMessage(_ message: ARTMessage) throws -> ARTMessage {
        let encoded = try message.encode(with: dataEncoder)
        return encoded as! ARTMessage
    }
    
    /**
     * Check if messages exceed maximum size
     */
    internal func exceedMaxSize(_ messages: [ARTBaseMessage]) -> Bool {
        let size = messages.reduce(0) { total, message in
            return total + message.messageSize()
        }
        return size > ARTDefault.maxMessageSize()
    }
    
    // MARK: - Abstract Methods
    
    /**
     * Post messages internally - must be overridden by subclasses
     */
    internal func internalPostMessages(_ data: Any, callback: ARTCallback?) {
        fatalError("internalPostMessages must be overridden by subclasses")
    }
    
    /**
     * History with wrapper SDK agents - must be overridden by subclasses  
     */
    internal func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion: @escaping ARTPaginatedMessagesCallback) {
        fatalError("historyWithWrapperSDKAgents must be overridden by subclasses")
    }
}

// MARK: - ARTChannelProtocol Implementation

extension ARTChannel: ARTChannelProtocol {
    
    public func publish(_ name: String?, data: Any?) {
        publish(name, data: data, callback: nil)
    }
    
    public func publish(_ name: String?, data: Any?, callback: ARTCallback?) {
        publish(name, data: data, extras: nil, callback: callback)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String) {
        publish(name, data: data, clientId: clientId, callback: nil)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?) {
        publish(name, data: data, clientId: clientId, extras: nil, callback: callback)
    }
    
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?) {
        publish(name, data: data, extras: extras, callback: nil)
    }
    
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        let message = ARTMessage(name: name, data: data)
        publish(name, message: message, extras: extras, callback: callback)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?) {
        publish(name, data: data, clientId: clientId, extras: extras, callback: nil)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        let message = ARTMessage(name: name, data: data, clientId: clientId)
        publish(name, message: message, extras: extras, callback: callback)
    }
    
    public func publish(_ messages: [ARTMessage]) {
        publish(messages, callback: nil)
    }
    
    public func publish(_ messages: [ARTMessage], callback: ARTCallback?) {
        do {
            // Encode all messages
            var encodedMessages: [ARTMessage] = []
            for message in messages {
                let encodedMessage = try encodeMessage(message)
                encodedMessages.append(encodedMessage)
            }
            
            // Check size limit after encoding
            if exceedMaxSize(encodedMessages) {
                let error = ARTErrorInfo.create(
                    withCode: 40009, // ARTErrorMaxMessageLengthExceeded
                    message: "Maximum message length exceeded."
                )
                callback?(error)
                return
            }
            
            internalPostMessages(encodedMessages, callback: callback)
            
        } catch {
            callback?(ARTErrorInfo.create(from: error))
        }
    }
    
    public func history(_ callback: @escaping ARTPaginatedMessagesCallback) {
        historyWithWrapperSDKAgents(nil, completion: callback)
    }
    
    // MARK: - Internal Publish Helper
    
    internal func publish(_ name: String?, message: ARTMessage, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        do {
            message.extras = extras
            let encodedMessage = try encodeMessage(message)
            
            // Check size limit after encoding
            if exceedMaxSize([encodedMessage]) {
                let error = ARTErrorInfo.create(
                    withCode: 40009, // ARTErrorMaxMessageLengthExceeded
                    message: "Maximum message length exceeded."
                )
                callback?(error)
                return
            }
            
            internalPostMessages(encodedMessage, callback: callback)
            
        } catch {
            callback?(ARTErrorInfo.create(from: error))
        }
    }
}

// MARK: - Placeholder Classes

/**
 * ARTDefault placeholder - will be migrated later
 */
internal class ARTDefault: @unchecked Sendable {
    internal static func maxMessageSize() -> Int {
        return 65536 // 64KB default
    }
}