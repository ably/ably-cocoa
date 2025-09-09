import Foundation

#if os(iOS)
import UIKit
#endif

// swift-migration: original location ARTLocalDevice+Private.h, line 8
let ARTDeviceIdKey = "ARTDeviceId"
// swift-migration: original location ARTLocalDevice+Private.h, line 9
let ARTDeviceSecretKey = "ARTDeviceSecret"
// swift-migration: original location ARTLocalDevice+Private.h, line 10
let ARTDeviceIdentityTokenKey = "ARTDeviceIdentityToken"
// swift-migration: original location ARTLocalDevice+Private.h, line 11
let ARTAPNSDeviceTokenKey = "ARTAPNSDeviceToken"
// swift-migration: original location ARTLocalDevice+Private.h, line 12
let ARTClientIdKey = "ARTClientId"

// swift-migration: original location ARTLocalDevice+Private.h, line 14
let ARTAPNSDeviceDefaultTokenType = "default"
// swift-migration: original location ARTLocalDevice+Private.h, line 15
let ARTAPNSDeviceLocationTokenType = "location"

// swift-migration: original location ARTLocalDevice.m, line 11
let ARTDevicePlatform = "ios"

// swift-migration: original location ARTLocalDevice.m, line 13-26
#if os(iOS)
let ARTDeviceFormFactor = "phone"
#elseif os(tvOS)
let ARTDeviceFormFactor = "tv"
#elseif os(watchOS)
let ARTDeviceFormFactor = "watch"
#elseif targetEnvironment(simulator)
let ARTDeviceFormFactor = "simulator"
#elseif os(macOS)
let ARTDeviceFormFactor = "desktop"
#else
let ARTDeviceFormFactor = "embedded"
#endif

// swift-migration: original location ARTLocalDevice.m, line 28
let ARTDevicePushTransportType = "apns"

// swift-migration: original location ARTLocalDevice+Private.h, line 17 and ARTLocalDevice.m, line 39
func ARTAPNSDeviceTokenKeyOfType(_ tokenType: String?) -> String {
    return ARTAPNSDeviceTokenKey + "-" + (tokenType ?? ARTAPNSDeviceDefaultTokenType)
}

// swift-migration: original location ARTLocalDevice.h, line 12 and ARTLocalDevice.m, line 49
public class ARTLocalDevice: ARTDeviceDetails {
    
    // swift-migration: original location ARTLocalDevice.h, line 17 and ARTLocalDevice.m, line 97
    public var identityTokenDetails: ARTDeviceIdentityTokenDetails? {
        return _identityTokenDetails
    }
    
    // swift-migration: original location ARTLocalDevice.h, line 22 and ARTLocalDevice+Private.h, line 22
    public private(set) var secret: String?
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 21
    internal var storage: ARTDeviceStorage
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 45 and ARTLocalDevice.m, line 54
    private let logger: ARTInternalLog?
    
    // swift-migration: original location ARTLocalDevice.m, line 97
    private var _identityTokenDetails: ARTDeviceIdentityTokenDetails?
    
    // swift-migration: original location ARTLocalDevice.h, line 25
    public required init() {
        fatalError("init() is not available")
    }
    
    // swift-migration: original location ARTLocalDevice.m, line 51
    internal init(storage: ARTDeviceStorage, logger: ARTInternalLog?) {
        self.storage = storage
        self.logger = logger
        super.init()
    }
    
    // swift-migration: original location ARTLocalDevice.m, line 59
    private func generateAndPersistPairOfDeviceIdAndSecret() {
        self.id = type(of: self).generateId()
        self.secret = type(of: self).generateSecret()
        
        storage.setObject(self.id, forKey: ARTDeviceIdKey)
        storage.setSecret(self.secret, forDevice: self.id!)
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 24 and ARTLocalDevice.m, line 67
    internal static func device(withStorage storage: ARTDeviceStorage, logger: ARTInternalLog?) -> ARTLocalDevice {
        let device = ARTLocalDevice(storage: storage, logger: logger)
        device.platform = ARTDevicePlatform
        
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            device.formFactor = "tablet"
        case .carPlay:
            device.formFactor = "car"
        default:
            device.formFactor = ARTDeviceFormFactor
        }
        #else
        device.formFactor = ARTDeviceFormFactor
        #endif
        
        device.push.recipient["transportType"] = ARTDevicePushTransportType
        
        let deviceId = storage.objectForKey(ARTDeviceIdKey) as? String
        let deviceSecret = deviceId == nil ? nil : storage.secretForDevice(deviceId!)
        
        if deviceId == nil || deviceSecret == nil {
            device.generateAndPersistPairOfDeviceIdAndSecret() // Should be removed later once spec issue #180 resolved.
        } else {
            device.id = deviceId!
            device.secret = deviceSecret!
        }
        
        let identityTokenDetailsInfo = storage.objectForKey(ARTDeviceIdentityTokenKey)
        let identityTokenDetails = ARTDeviceIdentityTokenDetails.unarchive(identityTokenDetailsInfo as? Data ?? Data(), withLogger: logger)
        device._identityTokenDetails = identityTokenDetails
        
        var clientId = storage.objectForKey(ARTClientIdKey) as? String
        if clientId == nil && identityTokenDetails?.clientId != nil {
            clientId = identityTokenDetails?.clientId // Older versions of the SDK did not persist clientId, so as a fallback when loading data persisted by these versions we use the clientId of the stored identity token
            storage.setObject(clientId, forKey: ARTClientIdKey)
        }
        device.clientId = clientId
        
        let supportedTokenTypes = [
            ARTAPNSDeviceDefaultTokenType,
            ARTAPNSDeviceLocationTokenType
        ]
        
        for tokenType in supportedTokenTypes {
            let token = ARTLocalDevice.apnsDeviceTokenOfType(tokenType, fromStorage: storage)
            device.setAPNSDeviceToken(token, tokenType: tokenType)
        }
        
        return device
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 31 and ARTLocalDevice.m, line 118
    internal func setupDetails(withClientId clientId: String?) {
        if self.id == nil || self.secret == nil {
            generateAndPersistPairOfDeviceIdAndSecret()
        }
        
        self.clientId = clientId
        storage.setObject(clientId, forKey: ARTClientIdKey)
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 30 and ARTLocalDevice.m, line 130
    internal func resetDetails() {
        // Should be replaced later to resetting device's id/secret once spec issue #180 resolved.
        generateAndPersistPairOfDeviceIdAndSecret()
        
        self.clientId = nil
        storage.setObject(nil, forKey: ARTClientIdKey)
        setAndPersistIdentityTokenDetails(nil)
        let supportedTokenTypes = [
            ARTAPNSDeviceDefaultTokenType,
            ARTAPNSDeviceLocationTokenType
        ]
        for tokenType in supportedTokenTypes {
            setAndPersistAPNSDeviceToken(nil, tokenType: tokenType)
        }
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 33 and ARTLocalDevice.m, line 146
    internal static func generateId() -> String {
        return UUID().uuidString
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 34 and ARTLocalDevice.m, line 150
    internal static func generateSecret() -> String {
        let randomData = ARTCrypto.generateSecureRandomData(32)!
        let hash = ARTCrypto.generateHashSHA256(randomData)
        return hash.base64EncodedString(options: [])
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 36 and ARTLocalDevice.m, line 156
    internal static func apnsDeviceTokenOfType(_ tokenType: String?, fromStorage storage: ARTDeviceStorage) -> String? {
        let token = storage.objectForKey(ARTAPNSDeviceTokenKeyOfType(tokenType)) as? String
        if tokenType == ARTAPNSDeviceDefaultTokenType && token == nil {
            return storage.objectForKey(ARTAPNSDeviceTokenKey) as? String // Read legacy token
        }
        return token
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 25 and ARTLocalDevice.m, line 164
    internal var apnsDeviceToken: String? {
        let deviceTokens = self.push.recipient["apnsDeviceTokens"] as? [String: String]
        return deviceTokens?[ARTAPNSDeviceDefaultTokenType]
    }
    
    // swift-migration: original location ARTLocalDevice.m, line 169
    private func setAPNSDeviceToken(_ token: String?, tokenType: String) {
        let deviceTokens = (self.push.recipient["apnsDeviceTokens"] as? [String: String]) ?? (token != nil ? [:] : nil)
        if deviceTokens != nil {
            var mutableTokens = deviceTokens!
            mutableTokens[tokenType] = token
            self.push.recipient["apnsDeviceTokens"] = mutableTokens
        }
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 26 and ARTLocalDevice.m, line 175
    internal func setAndPersistAPNSDeviceToken(_ token: String?, tokenType: String) {
        storage.setObject(token, forKey: ARTAPNSDeviceTokenKeyOfType(tokenType))
        setAPNSDeviceToken(token, tokenType: tokenType)
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 27 and ARTLocalDevice.m, line 180
    internal func setAndPersistAPNSDeviceToken(_ token: String?) {
        setAndPersistAPNSDeviceToken(token, tokenType: ARTAPNSDeviceDefaultTokenType)
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 28 and ARTLocalDevice.m, line 184
    internal func setAndPersistIdentityTokenDetails(_ tokenDetails: ARTDeviceIdentityTokenDetails?) {
        storage.setObject(tokenDetails?.archive(withLogger: logger), forKey: ARTDeviceIdentityTokenKey)
        _identityTokenDetails = tokenDetails
        if self.clientId == nil {
            self.clientId = tokenDetails?.clientId
            storage.setObject(tokenDetails?.clientId, forKey: ARTClientIdKey)
        }
    }
    
    // swift-migration: original location ARTLocalDevice+Private.h, line 29 and ARTLocalDevice.m, line 194
    internal func isRegistered() -> Bool {
        return _identityTokenDetails != nil
    }
}