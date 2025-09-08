import Foundation

// swift-migration: original location ARTChannel+Private.h, line 9 and ARTChannel.m, line 14
internal class ARTChannel: NSObject {
    private let queue: DispatchQueue
    private var _options: ARTChannelOptions
    
    // swift-migration: original location ARTChannel.h, line 25 and ARTChannel+Private.h, line 13
    internal let name: String
    
    // swift-migration: original location ARTChannel+Private.h, line 15
    internal var dataEncoder: ARTDataEncoder!
    
    // swift-migration: original location ARTChannel+Private.h, line 18
    internal let logger: ARTInternalLog
    
    // swift-migration: original location ARTChannel+Private.h, line 11 and ARTChannel.m, line 19
    internal init(name: String, andOptions options: ARTChannelOptions, rest: ARTRestInternal, logger: ARTInternalLog) {
        self.name = name
        self.logger = logger
        self.queue = rest.queue
        self._options = options
        
        super.init()
        
        self._options.frozen = true
        var error: Error? = nil
        self.dataEncoder = ARTDataEncoder(cipherParams: self._options.cipher, logger: self.logger, error: &error)
        if error != nil {
            ARTLogWarn(self.logger, "creating ARTDataEncoder: \(error!)")
            self.dataEncoder = ARTDataEncoder(cipherParams: nil, logger: self.logger, error: &error)
        }
    }
    
    // swift-migration: original location ARTChannel+Private.h, line 23 and ARTChannel.m, line 36
    internal var options: ARTChannelOptions? {
        var ret: ARTChannelOptions? = nil
        queue.sync {
            ret = options_nosync
        }
        return ret
    }
    
    // swift-migration: original location ARTChannel+Private.h, line 24 and ARTChannel.m, line 44
    internal var options_nosync: ARTChannelOptions? {
        return _options
    }
    
    // swift-migration: original location ARTChannel+Private.h, line 25 and ARTChannel.m, line 48
    internal func setOptions(_ options: ARTChannelOptions?) {
        queue.sync {
            setOptions_nosync(options)
        }
    }
    
    // swift-migration: original location ARTChannel+Private.h, line 26 and ARTChannel.m, line 54
    internal func setOptions_nosync(_ options: ARTChannelOptions?) {
        _options = options ?? ARTChannelOptions()
        recreateDataEncoderWith(_options.cipher)
    }
    
    // swift-migration: original location ARTChannel.m, line 59
    private func recreateDataEncoderWith(_ cipher: ARTCipherParams?) {
        var error: Error? = nil
        self.dataEncoder = ARTDataEncoder(cipherParams: cipher, logger: self.logger, error: &error)
        
        if error != nil {
            ARTLogWarn(logger, "creating ARTDataEncoder: \(error!)")
            var errorIgnored: Error? = nil
            self.dataEncoder = ARTDataEncoder(cipherParams: nil, logger: self.logger, error: &errorIgnored)
        }
    }
    
    // swift-migration: original location ARTChannel.h, line 27 and ARTChannel.m, line 69
    internal func publish(_ name: String?, data: Any?) {
        publish(name, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTChannel.h, line 29 and ARTChannel.m, line 73
    internal func publish(_ name: String?, data: Any?, callback: ARTCallback?) {
        publish(name, data: data, extras: nil, callback: callback)
    }
    
    // swift-migration: original location ARTChannel.h, line 35 and ARTChannel.m, line 77
    internal func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?) {
        publish(name, data: data, extras: extras, callback: nil)
    }
    
    // swift-migration: original location ARTChannel.h, line 37 and ARTChannel.m, line 81
    internal func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        let message = ARTMessage(name: name, data: data)
        publish(name, message: message, extras: extras, callback: callback)
    }
    
    // swift-migration: original location ARTChannel.h, line 31 and ARTChannel.m, line 85
    internal func publish(_ name: String?, data: Any?, clientId: String) {
        publish(name, data: data, clientId: clientId, callback: nil)
    }
    
    // swift-migration: original location ARTChannel.h, line 39 and ARTChannel.m, line 89
    internal func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?) {
        publish(name, data: data, clientId: clientId, extras: extras, callback: nil)
    }
    
    // swift-migration: original location ARTChannel.h, line 33 and ARTChannel.m, line 93
    internal func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?) {
        publish(name, data: data, clientId: clientId, extras: nil, callback: callback)
    }
    
    // swift-migration: original location ARTChannel.h, line 41 and ARTChannel.m, line 97
    internal func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        let message = ARTMessage(name: name, data: data, clientId: clientId)
        publish(name, message: message, extras: extras, callback: callback)
    }
    
    // swift-migration: original location ARTChannel.m, line 101
    private func publish(_ name: String?, message: ARTMessage, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        var error: Error? = nil
        message.extras = extras
        let messagesWithDataEncoded = encodeMessageIfNeeded(message, error: &error)
        if error != nil {
            if let callback = callback {
                callback(ARTErrorInfo.createFromNSError(error!))
            }
            return
        }
        
        // Checked after encoding, so that the client can receive callback with encoding errors
        if exceedMaxSize([message]) {
            let sizeError = ARTErrorInfo(code: ARTErrorMaxMessageLengthExceeded, 
                                       message: "Maximum message length exceeded.")
            if let callback = callback {
                callback(sizeError)
            }
            return
        }
        
        internalPostMessages(messagesWithDataEncoded, callback: callback)
    }
    
    // swift-migration: original location ARTChannel.h, line 43 and ARTChannel.m, line 123
    internal func publish(_ messages: [ARTMessage]) {
        publish(messages, callback: nil)
    }
    
    // swift-migration: original location ARTChannel.h, line 45 and ARTChannel.m, line 127
    internal func publish(_ messages: [ARTMessage], callback: ARTCallback?) {
        var error: Error? = nil
        
        var messagesWithDataEncoded: [ARTMessage] = []
        for message in messages {
            messagesWithDataEncoded.append(encodeMessageIfNeeded(message, error: &error))
        }
        
        if error != nil {
            if let callback = callback {
                callback(ARTErrorInfo.createFromNSError(error!))
            }
            return
        }
        
        // Checked after encoding, so that the client can receive callback with encoding errors
        if exceedMaxSize(messages) {
            let sizeError = ARTErrorInfo(code: ARTErrorMaxMessageLengthExceeded,
                                       message: "Maximum message length exceeded.")
            if let callback = callback {
                callback(sizeError)
            }
            return
        }
        
        internalPostMessages(messagesWithDataEncoded, callback: callback)
    }
    
    // swift-migration: original location ARTChannel+Private.h, line 21 and ARTChannel.m, line 155
    internal func exceedMaxSize(_ messages: [ARTBaseMessage]) -> Bool {
        var size = 0
        for message in messages {
            size += message.messageSize()
        }
        return size > ARTDefault.maxMessageSize()
    }
    
    // swift-migration: original location ARTChannel.m, line 163
    private func encodeMessageIfNeeded(_ message: ARTMessage, error: inout Error?) -> ARTMessage {
        var e: Error? = nil
        let encodedMessage = message.encode(with: dataEncoder, error: &e)
        if e != nil {
            ARTLogError(self.logger, "ARTChannel: error encoding data: \(e!)")
        }
        error = e
        return encodedMessage
    }
    
    // swift-migration: original location ARTChannel.h, line 47 and ARTChannel.m, line 178
    internal func historyWithWrapperSDKAgents(_ wrapperSDKAgents: NSStringDictionary?, completion callback: @escaping ARTPaginatedMessagesCallback) {
        fatalError("-[\(type(of: self)) \(#function)] should always be overridden.")
    }
    
    // swift-migration: original location ARTChannel+Private.h, line 20 and ARTChannel.m, line 182
    internal func internalPostMessages(_ data: Any, callback: ARTCallback?) {
        fatalError("-[\(type(of: self)) \(#function)] should always be overridden.")
    }
}