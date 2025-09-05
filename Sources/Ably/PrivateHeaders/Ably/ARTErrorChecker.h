@import Foundation;

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 Checks an `ARTErrorInfo` to see whether it falls into a given class of errors defined by the client library specification.

 In addition to putting shared error logic in a common place, it allows us to provide a mock instance when testing components that need to perform error checking, without having to worry about creating representative errors in our test cases.
 */
NS_SWIFT_NAME(ErrorChecker)
@protocol ARTErrorChecker

/**
 Returns whether the given error is a token error, as defined by RTH15h1.
 */
- (BOOL)isTokenError:(ARTErrorInfo *)errorInfo;

@end

/**
 The implementation of `ARTErrorChecker` that should be used in non-test code.
 */
NS_SWIFT_NAME(DefaultErrorChecker)
@interface ARTDefaultErrorChecker: NSObject <ARTErrorChecker>
@end

NS_ASSUME_NONNULL_END
