@import Foundation;
#import <Ably/ARTStatus.h>

#ifdef ABLY_SUPPORTS_PLUGINS
@import _AblyPluginSupportPrivate;
#endif

NS_ASSUME_NONNULL_BEGIN

#ifdef ABLY_SUPPORTS_PLUGINS
@interface ARTErrorInfo () <APPublicErrorInfo>
@end
#endif

// Gets an HTTP status code from error code by taking first three digits. Doesn't perform any checks if the result is a valid status code.
NSInteger ARTHttpStatusCodeFromErrorCode(ARTErrorCode errorCode);

NS_ASSUME_NONNULL_END
