import Foundation

// swift-migration: original location ARTErrorChecker.h, line 13
/**
 Checks an `ARTErrorInfo` to see whether it falls into a given class of errors defined by the client library specification.

 In addition to putting shared error logic in a common place, it allows us to provide a mock instance when testing components that need to perform error checking, without having to worry about creating representative errors in our test cases.
 */
internal protocol ARTErrorChecker {
    
    // swift-migration: original location ARTErrorChecker.h, line 18
    /**
     Returns whether the given error is a token error, as defined by RTH15h1.
     */
    func isTokenError(_ errorInfo: ARTErrorInfo) -> Bool
}

// swift-migration: original location ARTErrorChecker.h, line 26 and ARTErrorChecker.m, line 5
/**
 The implementation of `ARTErrorChecker` that should be used in non-test code.
 */
internal class ARTDefaultErrorChecker: NSObject, ARTErrorChecker {
    
    // swift-migration: original location ARTErrorChecker.m, line 7
    func isTokenError(_ errorInfo: ARTErrorInfo) -> Bool {
        // RTH15h1
        return errorInfo.statusCode == 401 && errorInfo.code >= ARTErrorTokenErrorUnspecified && errorInfo.code < ARTErrorConnectionLimitsExceeded
    }
}