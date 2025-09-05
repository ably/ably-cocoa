import Foundation

/// :nodoc:
public class ARTDataEncoderOutput: @unchecked Sendable {
    
    public let data: Any?
    public let encoding: String?
    public let errorInfo: ARTErrorInfo?
    
    public init(data: Any?, encoding: String?, errorInfo: ARTErrorInfo?) {
        self.data = data
        self.encoding = encoding
        self.errorInfo = errorInfo
    }
}

/**
 * `ARTDataEncoder` is used to:
 *
 * - convert the `data` property of an `ARTMessage` into a format that's suitable to be sent over the wire; that is, to ensure that this `ARTMessage` can be placed inside an `ARTProtocolMessage`
 * - convert the `data` property of an `ARTMessage` contained inside an `ARTProtocolMessage` into something that's suitable to expose to the user of the SDK
 */
public class ARTDataEncoder: @unchecked Sendable {
    
    private let cipher: ARTChannelCipher?
    private let deltaCodec: ARTDeltaCodec?
    private var baseId: String = ""
    
    public init(cipherParams: ARTCipherParams?, logger: ARTInternalLog) throws {
        if let params = cipherParams {
            guard let cipher = ARTCrypto.cipher(with: params, logger: logger) else {
                throw NSError(domain: ARTAblyErrorDomain,
                             code: 0,
                             userInfo: [NSLocalizedDescriptionKey: "ARTDataEncoder failed to create cipher with name \(params.algorithm)"])
            }
            self.cipher = cipher
        } else {
            self.cipher = nil
        }
        
        self.deltaCodec = ARTDeltaCodec()
    }
    
    public func encode(_ data: Any?) -> ARTDataEncoderOutput {
        var encoding: String?
        var encoded: Any?
        var toBase64: Data?
        
        guard let data = data else {
            return ARTDataEncoderOutput(data: data, encoding: nil, errorInfo: nil)
        }
        
        var jsonEncoded: Data?
        if data is [Any] || data is [String: Any] {
            do {
                var options: JSONSerialization.WritingOptions = []
                if #available(macOS 10.13, iOS 11.0, tvOS 11.0, *) {
                    options = .sortedKeys
                }
                jsonEncoded = try JSONSerialization.data(withJSONObject: data, options: options)
                encoded = data
                encoding = "json"
            } catch {
                return ARTDataEncoderOutput(data: data, encoding: nil, errorInfo: ARTErrorInfo.create(from: error))
            }
        } else if let stringData = data as? String {
            encoding = ""
            encoded = stringData
        } else if let dataData = data as? Data {
            encoded = dataData
            toBase64 = dataData
        }
        
        if let cipher = self.cipher {
            if encoded is [Any] || encoded is [String: Any] {
                encoded = jsonEncoded
                encoding = String.artAddEncoding("utf-8", to: encoding)
            } else if let stringEncoded = encoded as? String {
                encoded = stringEncoded.data(using: .utf8)
                encoding = String.artAddEncoding("utf-8", to: encoding)
            }
            
            guard let encodedData = encoded as? Data else {
                return ARTDataEncoderOutput(data: data, encoding: nil, 
                                          errorInfo: ARTErrorInfo.create(withCode: 0, message: "must be String, Data, Array or Dictionary."))
            }
            
            var output: Data?
            let status = cipher.encrypt(encodedData, output: &output)
            if status.state != .ok {
                let errorInfo = status.errorInfo ?? ARTErrorInfo.create(withCode: 0, message: "encrypt failed")
                return ARTDataEncoderOutput(data: encoded, encoding: encoding, errorInfo: errorInfo)
            }
            toBase64 = output
            encoding = String.artAddEncoding(cipherEncoding(), to: encoding)
        } else if let jsonData = jsonEncoded {
            encoded = String(data: jsonData, encoding: .utf8)
        }
        
        if let base64Data = toBase64 {
            let base64String = base64Data.base64EncodedString()
            encoded = base64String
            encoding = String.artAddEncoding("base64", to: encoding)
        }
        
        guard let finalEncoded = encoded else {
            return ARTDataEncoderOutput(data: data, encoding: nil, 
                                      errorInfo: ARTErrorInfo.create(withCode: 0, message: "must be String, Data, Array or Dictionary."))
        }
        
        return ARTDataEncoderOutput(data: finalEncoded, encoding: encoding, errorInfo: nil)
    }
    
    public func decode(_ data: Any?, encoding: String?) -> ARTDataEncoderOutput {
        return decode(data, identifier: "", encoding: encoding)
    }
    
    public func decode(_ data: Any?, identifier: String, encoding: String?) -> ARTDataEncoderOutput {
        guard let data = data, let encoding = encoding else {
            setDeltaCodecBase(data, identifier: identifier)
            return ARTDataEncoderOutput(data: data, encoding: encoding, errorInfo: nil)
        }
        
        var errorInfo: ARTErrorInfo?
        let encodings = encoding.components(separatedBy: "/")
        var outputEncoding = encoding
        var currentData: Any? = data
        
        if !(encodings.last == "base64" || encodings.contains("vcdiff")) {
            // RTL19d2: Non-Base64-encoded non-delta message
            setDeltaCodecBase(currentData, identifier: identifier)
        }
        
        for i in stride(from: encodings.count, to: 0, by: -1) {
            errorInfo = nil
            let currentEncoding = encodings[i - 1]
            
            if currentEncoding == "base64" {
                if let dataAsData = currentData as? Data {
                    currentData = String(data: dataAsData, encoding: .utf8)
                }
                if let dataAsString = currentData as? String {
                    currentData = Data(base64Encoded: dataAsString)
                } else {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorInvalidMessageDataOrEncoding,
                                                  message: "invalid data type for 'base64' decoding: '\(type(of: currentData))'")
                }
                
                if i == encodings.count && !encodings.contains("vcdiff") {
                    // RTL19d1: Base64-encoded non-delta message
                    setDeltaCodecBase(currentData, identifier: identifier)
                }
            } else if currentEncoding.isEmpty || currentEncoding == "utf-8" {
                if let dataAsData = currentData as? Data {
                    currentData = String(data: dataAsData, encoding: .utf8)
                }
                if !(currentData is String) {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorInvalidMessageDataOrEncoding,
                                                  message: "invalid data type for '\(currentEncoding)' decoding: '\(type(of: currentData))'")
                }
            } else if currentEncoding == "json" {
                if let dataAsData = currentData as? Data {
                    currentData = String(data: dataAsData, encoding: .utf8)
                }
                if let dataAsString = currentData as? String {
                    do {
                        let jsonData = dataAsString.data(using: .utf8) ?? Data()
                        currentData = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    } catch {
                        errorInfo = ARTErrorInfo.create(from: error)
                    }
                } else if !(currentData is [Any]) && !(currentData is [String: Any]) {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorInvalidMessageDataOrEncoding,
                                                  message: "invalid data type for 'json' decoding: '\(type(of: currentData))'")
                }
            } else if let cipher = self.cipher, 
                      currentEncoding == cipherEncoding(),
                      let dataAsData = currentData as? Data {
                var output: Any?
                let status = cipher.decrypt(dataAsData, output: &output)
                if status.state != .ok {
                    errorInfo = status.errorInfo ?? ARTErrorInfo.create(withCode: ARTErrorInvalidMessageDataOrEncoding, message: "decrypt failed")
                } else {
                    currentData = output
                }
            } else if currentEncoding == "vcdiff",
                      let deltaCodec = self.deltaCodec,
                      let dataAsData = currentData as? Data {
                do {
                    currentData = try deltaCodec.applyDelta(dataAsData, deltaId: identifier, baseId: baseId)
                    if let decodedData = currentData {
                        setDeltaCodecBase(decodedData, identifier: identifier)
                    } else {
                        errorInfo = ARTErrorInfo.create(withCode: ARTErrorUnableToDecodeMessage, message: "Data is nil")
                    }
                } catch {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorUnableToDecodeMessage, message: error.localizedDescription)
                }
            } else {
                errorInfo = ARTErrorInfo.create(withCode: ARTErrorInvalidMessageDataOrEncoding,
                                              message: "unknown encoding: '\(currentEncoding)'")
            }
            
            if errorInfo == nil {
                outputEncoding = outputEncoding.artRemoveLastEncoding() ?? outputEncoding
            } else {
                break
            }
        }
        
        return ARTDataEncoderOutput(data: currentData, encoding: outputEncoding, errorInfo: errorInfo)
    }
    
    private func setDeltaCodecBase(_ data: Any?, identifier: String) {
        baseId = identifier
        if let dataAsData = data as? Data {
            deltaCodec?.setBase(dataAsData, withId: identifier)
        } else if let dataAsString = data as? String {
            // PC3a
            deltaCodec?.setBase(dataAsString.data(using: .utf8), withId: identifier)
        }
    }
    
    private func cipherEncoding() -> String {
        guard let cipher = self.cipher else { return "" }
        let keyLen = cipher.keyLength()
        
        if keyLen == 128 {
            return "cipher+aes-128-cbc"
        } else if keyLen == 256 {
            return "cipher+aes-256-cbc"
        }
        return ""
    }
}

// MARK: - String Extensions for Encoding

extension String {
    
    /// :nodoc:
    static func artAddEncoding(_ encoding: String, to string: String?) -> String {
        let base = string ?? ""
        return base.isEmpty ? encoding : "\(base)/\(encoding)"
    }
    
    /// :nodoc:
    func artLastEncoding() -> String {
        return (self as NSString).lastPathComponent
    }
    
    /// :nodoc:
    func artRemoveLastEncoding() -> String? {
        let encoding = (self as NSString).deletingLastPathComponent
        return encoding.isEmpty ? nil : encoding
    }
}

// MARK: - Forward Declarations

// These will be migrated in later phases
public protocol ARTChannelCipher {
    func keyLength() -> Int
    func encrypt(_ data: Data, output: inout Data?) -> ARTStatus
    func decrypt(_ data: Data, output: inout Any?) -> ARTStatus
}

public class ARTCipherParams: @unchecked Sendable {
    public let algorithm: String
    
    public init(algorithm: String) {
        self.algorithm = algorithm
    }
}

public class ARTCrypto: @unchecked Sendable {
    public static func cipher(with params: ARTCipherParams, logger: ARTInternalLog) -> ARTChannelCipher? {
        // Placeholder implementation - will be migrated in later phases
        fatalError("ARTCrypto.cipher not yet implemented in Swift migration")
    }
}

public class ARTDeltaCodec: @unchecked Sendable {
    public init() {
        // Placeholder implementation
    }
    
    public func setBase(_ data: Data?, withId identifier: String) {
        // Placeholder implementation
    }
    
    public func applyDelta(_ delta: Data, deltaId: String, baseId: String) throws -> Data? {
        // Placeholder implementation
        fatalError("ARTDeltaCodec.applyDelta not yet implemented in Swift migration")
    }
}

public class ARTStatus: @unchecked Sendable {
    public enum State {
        case ok
        case error
    }
    
    public let state: State
    public let errorInfo: ARTErrorInfo?
    
    public init(state: State, errorInfo: ARTErrorInfo? = nil) {
        self.state = state
        self.errorInfo = errorInfo
    }
}

public enum ARTLogLevel: Int, Comparable, @unchecked Sendable {
    case none = 0
    case error = 1
    case warn = 2
    case info = 3
    case debug = 4
    case verbose = 5
    
    public static func < (lhs: ARTLogLevel, rhs: ARTLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public class ARTInternalLog: @unchecked Sendable {
    public var logLevel: ARTLogLevel = .info
    
    public init(logLevel: ARTLogLevel = .info) {
        self.logLevel = logLevel
    }
    
    public func debug(_ message: String) {
        guard logLevel >= .debug else { return }
        print("[DEBUG] \(message)")
    }
    
    public func info(_ message: String) {
        guard logLevel >= .info else { return }
        print("[INFO] \(message)")
    }
    
    public func warn(_ message: String) {
        guard logLevel >= .warn else { return }
        print("[WARN] \(message)")
    }
    
    public func error(_ message: String) {
        guard logLevel >= .error else { return }
        print("[ERROR] \(message)")
    }
    
    public func verbose(_ message: String) {
        guard logLevel >= .verbose else { return }
        print("[VERBOSE] \(message)")
    }
}

// Error handling constants
public let ARTAblyErrorDomain = "io.ably.cocoa"
public let ARTErrorInvalidMessageDataOrEncoding = 40013
public let ARTErrorUnableToDecodeMessage = 40018