import Foundation
import AblyDeltaCodec

// swift-migration: original location ARTDataEncoder.h, line 13 and ARTDataEncoder.m, line 5
public class ARTDataEncoderOutput: NSObject {
    
    // swift-migration: original location ARTDataEncoder.h, line 15
    public let data: Any?
    // swift-migration: original location ARTDataEncoder.h, line 16
    public let encoding: String?
    // swift-migration: original location ARTDataEncoder.h, line 17
    public let errorInfo: ARTErrorInfo?
    
    // swift-migration: original location ARTDataEncoder.h, line 19 and ARTDataEncoder.m, line 7
    public init(data: Any?, encoding: String?, errorInfo: ARTErrorInfo?) {
        self.data = data
        self.encoding = encoding
        self.errorInfo = errorInfo
        super.init()
    }
}

// swift-migration: original location ARTDataEncoder.h, line 29 and ARTDataEncoder.m, line 19
public class ARTDataEncoder: NSObject {
    private let cipher: ARTChannelCipher?
    private let deltaCodec: ARTDeltaCodec
    private var baseId: String?
    
    // swift-migration: original location ARTDataEncoder.h, line 31 and ARTDataEncoder.m, line 25
    public init?(cipherParams: ARTCipherParams?, logger: ARTInternalLog, error: inout Error?) {
        do {
            if let params = cipherParams {
                self.cipher = try ARTCrypto.cipher(params: params, logger: logger)
            } else {
                self.cipher = nil
            }
            
            self.deltaCodec = ARTDeltaCodec()
            super.init()
        } catch let catchError {
            let desc = "ARTDataEncoder failed to create cipher with name \(cipherParams?.algorithm ?? "unknown")"
            error = NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: desc])
            return nil
        }
    }
    
    // swift-migration: original location ARTDataEncoder.m, line 46
    internal func setDeltaCodecBase(_ data: Any?, identifier: String) {
        baseId = identifier
        if let nsData = data as? Data {
            deltaCodec.setBase(nsData, withId: identifier)
        } else if let string = data as? String {
            // PC3a
            if let utf8Data = string.data(using: .utf8) {
                deltaCodec.setBase(utf8Data, withId: identifier)
            }
        }
    }
    
    // swift-migration: original location ARTDataEncoder.h, line 32 and ARTDataEncoder.m, line 57
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
                // Just check the error; we don't want to actually JSON-encode this. It's more like "convert to JSON-compatible data".
                // We will store the result, though, because if we're encrypting, then yes, we need to use the JSON-encoded
                // data before encrypting.
                var options: JSONSerialization.WritingOptions = []
                if #available(macOS 10.13, iOS 11.0, tvOS 11.0, *) {
                    options = .sortedKeys
                }
                jsonEncoded = try JSONSerialization.data(withJSONObject: data, options: options)
                encoded = data
                encoding = "json"
            } catch {
                return ARTDataEncoderOutput(data: data, encoding: nil, errorInfo: ARTErrorInfo.createFromNSError(error as NSError))
            }
        } else if let stringData = data as? String {
            encoding = ""
            encoded = stringData
        } else if let nsData = data as? Data {
            encoded = nsData
            toBase64 = nsData
        }
        
        if let cipher = self.cipher {
            if encoded is [Any] || encoded is [String: Any] {
                encoded = jsonEncoded
                encoding = NSString.artAddEncoding("utf-8", toString: encoding)
            } else if let stringData = encoded as? String {
                encoded = stringData.data(using: .utf8)
                encoding = NSString.artAddEncoding("utf-8", toString: encoding)
            }
            guard let encodedData = encoded as? Data else {
                return ARTDataEncoderOutput(data: data, encoding: nil, errorInfo: ARTErrorInfo.create(withCode: 0, message: "must be NSString, NSData, NSArray or NSDictionary."))
            }
            
            var output: Data?
            let status = cipher.encrypt(encodedData, output: &output)
            if status.state != .ok {
                let errorInfo = status.errorInfo ?? ARTErrorInfo.create(withCode: 0, message: "encrypt failed")
                return ARTDataEncoderOutput(data: encoded, encoding: encoding, errorInfo: errorInfo)
            }
            toBase64 = output
            encoding = NSString.artAddEncoding(cipherEncoding(), toString: encoding)
        } else if let jsonData = jsonEncoded {
            encoded = String(data: jsonData, encoding: .utf8)
        }
        
        if let toBase64 = toBase64 {
            let base64String = toBase64.base64EncodedString(options: [])
            guard let base64Data = base64String.data(using: .utf8) else {
                return ARTDataEncoderOutput(data: toBase64, encoding: encoding, errorInfo: ARTErrorInfo.create(withCode: 0, message: "base64 failed"))
            }
            encoded = String(data: base64Data, encoding: .utf8)
            encoding = NSString.artAddEncoding("base64", toString: encoding)
        }
        
        guard let finalEncoded = encoded else {
            return ARTDataEncoderOutput(data: data, encoding: nil, errorInfo: ARTErrorInfo.create(withCode: 0, message: "must be NSString, NSData, NSArray or NSDictionary."))
        }
        
        return ARTDataEncoderOutput(data: finalEncoded, encoding: encoding, errorInfo: nil)
    }
    
    // swift-migration: original location ARTDataEncoder.h, line 33 and ARTDataEncoder.m, line 132
    public func decode(_ data: Any?, encoding: String?) -> ARTDataEncoderOutput {
        return decode(data, identifier: "", encoding: encoding)
    }
    
    // swift-migration: original location ARTDataEncoder.h, line 34 and ARTDataEncoder.m, line 136
    public func decode(_ data: Any?, identifier: String, encoding: String?) -> ARTDataEncoderOutput {
        guard let data = data, let encoding = encoding else {
            setDeltaCodecBase(data, identifier: identifier)
            return ARTDataEncoderOutput(data: data, encoding: encoding, errorInfo: nil)
        }
        
        var errorInfo: ARTErrorInfo?
        let encodings = encoding.components(separatedBy: "/")
        var outputEncoding = encoding
        var currentData = data
        
        if !((encodings.last == "base64") || encodings.contains("vcdiff")) {
            // RTL19d2: Non-Base64-encoded non-delta message
            setDeltaCodecBase(currentData, identifier: identifier)
        }
        
        for i in stride(from: encodings.count, to: 0, by: -1) {
            errorInfo = nil
            let currentEncoding = encodings[i - 1]
            
            if currentEncoding == "base64" {
                if let nsData = currentData as? Data { // E. g. when decrypted.
                    currentData = String(data: nsData, encoding: .utf8)
                }
                if let stringData = currentData as? String {
                    // Note that this, in combination with the vcdiff decoding step below, gives us RTL19e1 (deriving the base payload in the case of a Base64-encoded delta message)
                    currentData = Data(base64Encoded: stringData)
                } else {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorInvalidMessageDataOrEncoding.rawValue, message: "invalid data type for 'base64' decoding: '\(type(of: currentData))'")
                }
                
                if i == encodings.count && !encodings.contains("vcdiff") {
                    // RTL19d1: Base64-encoded non-delta message
                    setDeltaCodecBase(currentData, identifier: identifier)
                }
            } else if currentEncoding == "" || currentEncoding == "utf-8" {
                if let nsData = currentData as? Data { // E. g. when decrypted.
                    currentData = String(data: nsData, encoding: .utf8)
                }
                if !(currentData is String) {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorInvalidMessageDataOrEncoding.rawValue, message: "invalid data type for '\(currentEncoding)' decoding: '\(type(of: currentData))'")
                }
            } else if currentEncoding == "json" {
                if let nsData = currentData as? Data { // E. g. when decrypted.
                    currentData = String(data: nsData, encoding: .utf8)
                }
                if let stringData = currentData as? String {
                    if let jsonData = stringData.data(using: .utf8) {
                        do {
                            currentData = try JSONSerialization.jsonObject(with: jsonData, options: [])
                        } catch {
                            errorInfo = ARTErrorInfo.createFromNSError(error as NSError)
                        }
                    }
                } else if !(currentData is [Any]) && !(currentData is [String: Any]) {
                    errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorInvalidMessageDataOrEncoding.rawValue, message: "invalid data type for 'json' decoding: '\(type(of: currentData))'")
                }
            } else if let cipher = self.cipher, currentEncoding == cipherEncoding(), let nsData = currentData as? Data {
                var output: Data?
                let status = cipher.decrypt(nsData, output: &output)
                if status.state != .ok {
                    errorInfo = status.errorInfo ?? ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorInvalidMessageDataOrEncoding.rawValue, message: "decrypt failed")
                } else {
                    currentData = output
                }
            } else if currentEncoding == "vcdiff", let nsData = currentData as? Data {
                do {
                    currentData = try deltaCodec.applyDelta(nsData, deltaId: identifier, baseId: baseId ?? "")
                    
                    // RTL19e
                    if currentData != nil {
                        setDeltaCodecBase(currentData, identifier: identifier)
                    }
                } catch {
                    if currentData == nil {
                        errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue, message: "Data is nil")
                    } else {
                        errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue, message: error.localizedDescription)
                    }
                }
            } else {
                errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorInvalidMessageDataOrEncoding.rawValue, message: "unknown encoding: '\(currentEncoding)'")
            }
            
            if errorInfo == nil {
                outputEncoding = outputEncoding.artRemoveLastEncoding() ?? ""
            } else {
                break
            }
        }
        
        return ARTDataEncoderOutput(data: currentData, encoding: outputEncoding.isEmpty ? nil : outputEncoding, errorInfo: errorInfo)
    }
    
    // swift-migration: original location ARTDataEncoder.m, line 231
    private func cipherEncoding() -> String {
        guard let cipher = self.cipher else { return "" }
        
        let keyLen = cipher.keyLength
        if keyLen == 128 {
            return "cipher+aes-128-cbc"
        } else if keyLen == 256 {
            return "cipher+aes-256-cbc"
        }
        return ""
    }
}

// swift-migration: original location ARTDataEncoder.h, line 39 and ARTDataEncoder.m, line 243
extension NSString {
    
    // swift-migration: original location ARTDataEncoder.h, line 41 and ARTDataEncoder.m, line 245
    class func artAddEncoding(_ encoding: String?, toString s: String?) -> String {
        return ((s ?? "") as NSString).appendingPathComponent(encoding ?? "")
    }
}

extension String {
    
    // swift-migration: original location ARTDataEncoder.h, line 42 and ARTDataEncoder.m, line 249
    func artLastEncoding() -> String {
        return (self as NSString).lastPathComponent
    }
    
    // swift-migration: original location ARTDataEncoder.h, line 43 and ARTDataEncoder.m, line 253
    func artRemoveLastEncoding() -> String? {
        let encoding = (self as NSString).deletingLastPathComponent
        if encoding.isEmpty {
            return nil
        }
        return encoding
    }
}
