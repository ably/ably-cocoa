#import "ARTConnectionDetails.h"

#ifdef ABLY_SUPPORTS_PLUGINS
@import _AblyPluginSupportPrivate;
#endif

#ifdef ABLY_SUPPORTS_PLUGINS
@interface ARTConnectionDetails () <APConnectionDetailsProtocol>
@end
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnectionDetails ()

@property (readwrite, nonatomic, nullable) NSString *clientId;
@property (readwrite, nonatomic, nullable) NSString *connectionKey;

- (void)setMaxIdleInterval:(NSTimeInterval)seconds;

@end

NS_ASSUME_NONNULL_END
