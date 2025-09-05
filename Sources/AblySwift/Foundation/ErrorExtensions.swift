import Foundation

// MARK: - Error Extensions

// Note: ARTErrorInfoRequestIdKey will need to be defined elsewhere
let ARTErrorInfoRequestIdKey = "ARTErrorInfoRequestId"

extension NSError {
    /// Creates a copy of the error with a request ID
    static func copy(from error: NSError, withRequestId requestId: String?) -> NSError {
        var mutableInfo = error.userInfo
        mutableInfo[ARTErrorInfoRequestIdKey] = requestId
        
        return NSError(domain: error.domain, code: error.code, userInfo: mutableInfo)
    }
    
    /// Gets the request ID from the error's userInfo
    var requestId: String? {
        return userInfo[ARTErrorInfoRequestIdKey] as? String
    }
}