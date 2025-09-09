import Foundation

// swift-migration: original location NSError+ARTUtils.h, line 5 and NSError+ARTUtils.m, line 4
internal extension NSError {
    
    // swift-migration: original location NSError+ARTUtils.h, line 7 and NSError+ARTUtils.m, line 13
    // swift-migration: requestId property moved to ARTErrorInfo extension in ARTStatus.swift to avoid conflicts
    
    // swift-migration: original location NSError+ARTUtils.h, line 9 and NSError+ARTUtils.m, line 6
    static func copyFromError(_ error: NSError, withRequestId requestId: String?) -> NSError {
        var mutableInfo = error.userInfo
        mutableInfo[ARTErrorInfoRequestIdKey] = requestId
        
        return NSError(domain: error.domain, code: error.code, userInfo: mutableInfo)
    }
}