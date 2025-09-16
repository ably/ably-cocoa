import Foundation
import Security

// swift-migration: original location ARTLocalDeviceStorage.h, line 9 and ARTLocalDeviceStorage.m, line 5
internal class ARTLocalDeviceStorage: NSObject, ARTDeviceStorage {
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 6
    private let logger: InternalLog
    
    // swift-migration: original location ARTLocalDeviceStorage.h, line 11 and ARTLocalDeviceStorage.m, line 9
    internal init(logger: InternalLog) {
        self.logger = logger
        super.init()
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.h, line 13 and ARTLocalDeviceStorage.m, line 16
    internal static func new(withLogger logger: InternalLog) -> ARTLocalDeviceStorage {
        return ARTLocalDeviceStorage(logger: logger)
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 20
    func objectForKey(_ key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 24
    func setObject(_ value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 28
    func secretForDevice(_ deviceId: String) -> String? {
        do {
            let value = try keychainGetPassword(forService: ARTDeviceSecretKey, account: deviceId)
            return value
        } catch let error as NSError {
            if error.code == Int(errSecItemNotFound) {
                ARTLogDebug(logger, "Device Secret not found")
            } else {
                ARTLogError(logger, "Device Secret couldn't be read (\(error.localizedDescription))")
            }
            return nil
        }
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 42
    func setSecret(_ value: String?, forDevice deviceId: String) {
        do {
            if value == nil {
                try keychainDeletePassword(forService: ARTDeviceSecretKey, account: deviceId)
            } else {
                try keychainSetPassword(value!, forService: ARTDeviceSecretKey, account: deviceId)
            }
        } catch let error as NSError {
            if error.code == Int(errSecItemNotFound) {
                ARTLogWarn(logger, "Device Secret can't be deleted because it doesn't exist")
            } else {
                ARTLogError(logger, "Device Secret couldn't be updated (\(error.localizedDescription))")
            }
        }
    }
    
    // MARK: - Keychain
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 65
    private func newKeychainQuery(forService serviceName: String, account: String) -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary[kSecClass as String] = kSecClassGenericPassword
        dictionary[kSecAttrService as String] = serviceName
        dictionary[kSecAttrAccount as String] = account
        #if os(iOS) || os(watchOS) || os(tvOS)
        dictionary[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #endif
        return dictionary
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 76
    private func keychainError(withCode status: OSStatus) -> NSError {
        var message: String?
        
        #if os(iOS) || os(watchOS) || os(tvOS)
        switch status {
        case errSecUnimplemented:
            message = "errSecUnimplemented"
        case errSecParam:
            message = "errSecParam"
        case errSecAllocate:
            message = "errSecAllocate"
        case errSecNotAvailable:
            message = "errSecNotAvailable"
        case errSecDuplicateItem:
            message = "errSecDuplicateItem"
        case errSecItemNotFound:
            message = "errSecItemNotFound"
        case errSecInteractionNotAllowed:
            message = "errSecInteractionNotAllowed"
        case errSecDecode:
            message = "errSecDecode"
        case errSecAuthFailed:
            message = "errSecAuthFailed"
        default:
            message = "errSecDefault"
        }
        #else
        message = SecCopyErrorMessageString(status, nil) as String?
        #endif
        
        var userInfo: [String: Any]? = nil
        if let message = message {
            userInfo = [NSLocalizedDescriptionKey: message]
        }
        
        return NSError(domain: "\(ARTAblyErrorDomain).Keychain", code: Int(status), userInfo: userInfo)
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 130
    private func keychainGetPassword(forService serviceName: String, account: String) throws -> String? {
        var query = newKeychainQuery(forService: serviceName, account: account)
        
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status != errSecSuccess {
            throw keychainError(withCode: status)
        } else {
            if let passwordData = result as? Data, !passwordData.isEmpty {
                return String(data: passwordData, encoding: .utf8)
            }
        }
        
        return nil
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 153
    @discardableResult
    private func keychainDeletePassword(forService serviceName: String, account: String) throws -> Bool {
        let query = newKeychainQuery(forService: serviceName, account: account)
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess {
            throw keychainError(withCode: status)
        }
        
        return status == errSecSuccess
    }
    
    // swift-migration: original location ARTLocalDeviceStorage.m, line 162
    @discardableResult
    private func keychainSetPassword(_ password: String, forService serviceName: String, account: String) throws -> Bool {
        let passwordData = password.data(using: .utf8)!
        let searchQuery = newKeychainQuery(forService: serviceName, account: account)
        
        var status = SecItemCopyMatching(searchQuery as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Item already exists, update it
            var updateQuery: [String: Any] = [:]
            updateQuery[kSecValueData as String] = passwordData
            status = SecItemUpdate(searchQuery as CFDictionary, updateQuery as CFDictionary)
        } else if status == errSecItemNotFound {
            // Item not found, create it
            var insertQuery = newKeychainQuery(forService: serviceName, account: account)
            insertQuery[kSecValueData as String] = passwordData
            status = SecItemAdd(insertQuery as CFDictionary, nil)
        }
        
        if status != errSecSuccess {
            throw keychainError(withCode: status)
        }
        
        return status == errSecSuccess
    }
}
