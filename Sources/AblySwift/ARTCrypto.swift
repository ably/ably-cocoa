import Foundation
import CommonCrypto
import Security

// swift-migration: original location ARTCrypto.m, line 6
private let cbcBlockLength = 16

// swift-migration: original location ARTCrypto.h, line 9 and ARTCrypto.m, line 9
public protocol ARTCipherKeyCompatible {
    func toData() -> Data
}

// swift-migration: original location ARTCrypto.h, line 14 and ARTCrypto.m, line 20
extension String: ARTCipherKeyCompatible {
    
    // swift-migration: original location ARTCrypto.h, line 15 and ARTCrypto.m, line 22
    public func toData() -> Data {
        var key = self
        key = key.replacingOccurrences(of: "-", with: "+")
        key = key.replacingOccurrences(of: "_", with: "/")
        return Data(base64Encoded: key) ?? Data()
    }
}

// swift-migration: original location ARTCrypto.h, line 19 and ARTCrypto.m, line 31
extension Data: ARTCipherKeyCompatible {
    
    // swift-migration: original location ARTCrypto.h, line 20 and ARTCrypto.m, line 33
    public func toData() -> Data {
        return self
    }
}

// swift-migration: original location ARTCrypto.h, line 26
public protocol ARTCipherParamsCompatible {
    func toCipherParams() -> ARTCipherParams
}

// swift-migration: original location ARTCrypto.h, line 31 and ARTCrypto.m, line 105
extension Dictionary: ARTCipherParamsCompatible where Key == String, Value == Any {
    
    // swift-migration: original location ARTCrypto.h, line 32 and ARTCrypto.m, line 107
    public func toCipherParams() -> ARTCipherParams {
        return ARTCrypto.getDefaultParams(self)
    }
}

// swift-migration: original location ARTCrypto.h, line 38 and ARTCrypto.m, line 39
public class ARTCipherParams: NSObject, ARTCipherParamsCompatible {
    
    // swift-migration: original location ARTCrypto.h, line 43
    public let algorithm: String
    // swift-migration: original location ARTCrypto.h, line 48
    public let key: Data
    // swift-migration: original location ARTCrypto.h, line 53
    public let keyLength: UInt
    // swift-migration: original location ARTCrypto+Private.h, line 9
    internal let iv: Data?
    
    // swift-migration: original location ARTCrypto.h, line 58
    public var mode: String {
        return getMode()
    }
    
    // swift-migration: original location ARTCrypto.h, line 64 and ARTCrypto.m, line 41
    public init(algorithm: String, key: ARTCipherKeyCompatible) {
        let keyData = key.toData()
        self.algorithm = algorithm
        self.key = keyData
        self.keyLength = UInt(keyData.count * 8)
        self.iv = nil
        super.init()
        
        var ccAlgorithm: CCAlgorithm = 0
        do {
            try self.ccAlgorithm(&ccAlgorithm)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 10 and ARTCrypto.m, line 46
    internal init(algorithm: String, key: ARTCipherKeyCompatible, iv: Data?) {
        let keyData = key.toData()
        self.algorithm = algorithm
        self.key = keyData
        self.keyLength = UInt(keyData.count * 8)
        self.iv = iv
        super.init()
        
        var ccAlgorithm: CCAlgorithm = 0
        do {
            try self.ccAlgorithm(&ccAlgorithm)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    // swift-migration: original location ARTCrypto.m, line 63
    private func getMode() -> String {
        return "CBC"
    }
    
    // swift-migration: original location ARTCrypto.m, line 8 and ARTCrypto.m, line 67
    internal func ccAlgorithm(_ algorithm: inout CCAlgorithm) throws {
        var errorMsg: String?
        
        if self.algorithm.caseInsensitiveCompare("AES") == .orderedSame {
            if let iv = self.iv, iv.count != cbcBlockLength {
                errorMsg = "iv length expected to be \(cbcBlockLength), got \(iv.count) instead"
            } else if self.keyLength != 128 && self.keyLength != 256 {
                errorMsg = "invalid key length for AES algorithm: \(self.keyLength)"
            } else {
                algorithm = CCAlgorithm(kCCAlgorithmAES)
            }
        } else if self.algorithm.caseInsensitiveCompare("DES") == .orderedSame {
            algorithm = CCAlgorithm(kCCAlgorithmDES)
        } else if self.algorithm.caseInsensitiveCompare("3DES") == .orderedSame {
            algorithm = CCAlgorithm(kCCAlgorithm3DES)
        } else if self.algorithm.caseInsensitiveCompare("CAST") == .orderedSame {
            algorithm = CCAlgorithm(kCCAlgorithmCAST)
        } else if self.algorithm.caseInsensitiveCompare("RC4") == .orderedSame {
            algorithm = CCAlgorithm(kCCAlgorithmRC4)
        } else if self.algorithm.caseInsensitiveCompare("RC2") == .orderedSame {
            algorithm = CCAlgorithm(kCCAlgorithmRC2)
        } else {
            errorMsg = "unknown algorithm: \(self.algorithm)"
        }
        
        if let errorMsg = errorMsg {
            throw NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: errorMsg])
        }
    }
    
    // swift-migration: original location ARTCrypto.h, line 67 and ARTCrypto.m, line 99
    public func toCipherParams() -> ARTCipherParams {
        return self
    }
}

// swift-migration: original location ARTCrypto+Private.h, line 14
internal protocol ARTChannelCipher {
    func encrypt(_ plaintext: Data, output: inout Data?) -> ARTStatus
    func decrypt(_ ciphertext: Data, output: inout Data?) -> ARTStatus
    var cipherName: String? { get }
    var keyLength: Int { get }
}

// swift-migration: original location ARTCrypto+Private.h, line 23 and ARTCrypto.m, line 113
internal class ARTCbcCipher: NSObject, ARTChannelCipher {
    
    // swift-migration: original location ARTCrypto+Private.h, line 30
    internal let keySpec: Data
    // swift-migration: original location ARTCrypto+Private.h, line 31
    internal var iv: Data?
    // swift-migration: original location ARTCrypto+Private.h, line 32
    internal let blockLength: UInt
    // swift-migration: original location ARTCrypto+Private.h, line 29
    internal let logger: ARTInternalLog
    // swift-migration: original location ARTCrypto.m, line 16
    private let algorithm: CCAlgorithm
    
    // swift-migration: original location ARTCrypto+Private.h, line 25 and ARTCrypto.m, line 115
    internal init(cipherParams: ARTCipherParams, logger: ARTInternalLog) throws {
        self.keySpec = cipherParams.key
        self.iv = cipherParams.iv
        self.blockLength = UInt(cbcBlockLength)
        self.logger = logger
        
        var ccAlgorithm: CCAlgorithm = 0
        try cipherParams.ccAlgorithm(&ccAlgorithm)
        self.algorithm = ccAlgorithm
        
        super.init()
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 19 and ARTCrypto.m, line 130
    internal var keyLength: Int {
        return keySpec.count * 8
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 26 and ARTCrypto.m, line 134
    class func cbcCipher(params: ARTCipherParams, logger: ARTInternalLog) throws -> ARTCbcCipher {
        return try ARTCbcCipher(cipherParams: params, logger: logger)
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 16 and ARTCrypto.m, line 138
    internal func encrypt(_ plaintext: Data, output: inout Data?) -> ARTStatus {
        guard let iv = self.iv ?? ARTCrypto.generateSecureRandomData(Int(self.blockLength)) else {
            ARTLogError(self.logger, "ARTCrypto error encrypting")
            return ARTStatus(state: .error)
        }
        
        // The maximum cipher text is plaintext length + block length. We are also prepending this with the IV so need 2 block lengths in addition to the plaintext length.
        let outputBufLen = plaintext.count + Int(self.blockLength) * 2
        let buf = UnsafeMutableRawPointer.allocate(byteCount: outputBufLen, alignment: 1)
        
        // Copy the iv first
        iv.withUnsafeBytes { ivBytes in
            buf.copyMemory(from: ivBytes.baseAddress!, byteCount: Int(self.blockLength))
        }
        
        let ciphertextBuf = buf.advanced(by: Int(self.blockLength))
        let ciphertextBufLen = outputBufLen - Int(self.blockLength)
        
        var bytesWritten: size_t = 0
        let status = keySpec.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                plaintext.withUnsafeBytes { plaintextBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        algorithm,
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        keySpec.count,
                        ivBytes.baseAddress,
                        plaintextBytes.baseAddress,
                        plaintext.count,
                        ciphertextBuf,
                        ciphertextBufLen,
                        &bytesWritten
                    )
                }
            }
        }
        
        if status != kCCSuccess {
            ARTLogError(self.logger, "ARTCrypto error encrypting. Status is \(status)")
            buf.deallocate()
            return ARTStatus(state: .error)
        }
        
        let ciphertext = Data(bytesNoCopy: buf, count: bytesWritten + Int(self.blockLength), deallocator: .free)
        if ciphertext.isEmpty {
            ARTLogError(self.logger, "ARTCrypto error encrypting. cipher text is nil")
            buf.deallocate()
            return ARTStatus(state: .error)
        }
        
        output = ciphertext
        return ARTStatus(state: .ok)
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 17 and ARTCrypto.m, line 185
    internal func decrypt(_ ciphertext: Data, output: inout Data?) -> ARTStatus {
        // The first *blockLength* bytes are the iv
        if ciphertext.count < Int(self.blockLength) {
            return ARTStatus(state: .invalidArgs)
        }
        
        let ivData = ciphertext.subdata(in: 0..<Int(self.blockLength))
        let actualCiphertext = ciphertext.subdata(in: Int(self.blockLength)..<ciphertext.count)
        
        let options: CCOptions = 0
        
        // The output will never be more than the input + block length
        let outputLength = actualCiphertext.count + Int(self.blockLength)
        let buf = UnsafeMutableRawPointer.allocate(byteCount: outputLength, alignment: 1)
        var bytesWritten: size_t = 0
        
        // Decrypt without padding because CCCrypt does not return an error code
        // if the decrypted value is not padded correctly
        let status = keySpec.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                actualCiphertext.withUnsafeBytes { ciphertextBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        algorithm,
                        options,
                        keyBytes.baseAddress,
                        keySpec.count,
                        ivBytes.baseAddress,
                        ciphertextBytes.baseAddress,
                        actualCiphertext.count,
                        buf,
                        outputLength,
                        &bytesWritten
                    )
                }
            }
        }
        
        if status != kCCSuccess {
            ARTLogError(self.logger, "ARTCrypto error decrypting. Status is \(status)")
            buf.deallocate()
            return ARTStatus(state: .error)
        }
        
        // Check that the decrypted value is padded correctly and determine the unpadded length
        let cbuf = buf.bindMemory(to: Int8.self, capacity: bytesWritten)
        let paddingLength = Int(cbuf[bytesWritten - 1])
        
        if paddingLength == 0 || paddingLength > bytesWritten {
            buf.deallocate()
            return ARTStatus(state: .cryptoBadPadding)
        }
        
        for i in stride(from: bytesWritten - 1, to: bytesWritten - paddingLength, by: -1) {
            if paddingLength != Int(cbuf[i - 1]) {
                buf.deallocate()
                return ARTStatus(state: .cryptoBadPadding)
            }
        }
        
        let unpaddedLength = bytesWritten - paddingLength
        let plaintext = Data(bytesNoCopy: buf, count: unpaddedLength, deallocator: .free)
        if plaintext.isEmpty {
            ARTLogError(self.logger, "ARTCrypto error decrypting. plain text is nil")
            buf.deallocate()
        }
        
        output = plaintext
        return ARTStatus(state: .ok)
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 18 and ARTCrypto.m, line 250
    internal var cipherName: String? {
        let algo: String
        switch algorithm {
        case CCAlgorithm(kCCAlgorithmAES):
            algo = "aes"
        case CCAlgorithm(kCCAlgorithmDES):
            algo = "des"
        case CCAlgorithm(kCCAlgorithm3DES):
            algo = "3des"
        case CCAlgorithm(kCCAlgorithmCAST):
            algo = "cast"
        case CCAlgorithm(kCCAlgorithmRC4):
            algo = "rc4"
        case CCAlgorithm(kCCAlgorithmRC2):
            algo = "rc2"
        default:
            fatalError("Invalid algorithm")
        }
        return "\(algo)-cbc"
    }
}

// swift-migration: original location ARTCrypto.h, line 74 and ARTCrypto.m, line 280
public class ARTCrypto: NSObject {
    
    // swift-migration: original location ARTCrypto+Private.h, line 38 and ARTCrypto.m, line 282
    public class func defaultAlgorithm() -> String {
        return "AES"
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 39 and ARTCrypto.m, line 286
    internal class func defaultKeyLength() -> Int {
        return 256
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 40 and ARTCrypto.m, line 290
    internal class func defaultBlockLength() -> Int {
        return 128
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 42 and ARTCrypto.m, line 294
    internal class func generateSecureRandomData(_ length: Int) -> Data? {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        return result == errSecSuccess ? data : nil
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 43 and ARTCrypto.m, line 312
    internal class func generateHashSHA256(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bytes in
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }
    
    // swift-migration: original location ARTCrypto.h, line 82 and ARTCrypto.m, line 320
    public class func getDefaultParams(_ cipherParams: [String: Any]) -> ARTCipherParams {
        let algorithm = cipherParams["algorithm"] as? String ?? ARTCrypto.defaultAlgorithm()
        guard let key = cipherParams["key"] as? String else {
            fatalError("missing key parameter")
        }
        return ARTCipherParams(algorithm: algorithm, key: key)
    }
    
    // swift-migration: original location ARTCrypto.h, line 99 and ARTCrypto.m, line 332
    public class func generateRandomKey() -> Data? {
        return generateRandomKey(UInt(defaultKeyLength()))
    }
    
    // swift-migration: original location ARTCrypto.h, line 91 and ARTCrypto.m, line 336
    public class func generateRandomKey(_ length: UInt) -> Data? {
        return generateSecureRandomData(Int(length / 8))
    }
    
    // swift-migration: original location ARTCrypto+Private.h, line 45 and ARTCrypto.m, line 340
    internal class func cipher(params: ARTCipherParams, logger: ARTInternalLog) throws -> ARTChannelCipher {
        return try ARTCbcCipher.cbcCipher(params: params, logger: logger)
    }
}