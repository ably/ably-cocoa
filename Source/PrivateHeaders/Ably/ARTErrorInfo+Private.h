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

NS_ASSUME_NONNULL_END
