@import Foundation;
#import <Ably/ARTClientOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provides an interface for injecting additional configuration into `ARTRest` or `ARTRealtime` instances.

 This is for anything that test code wishes to be able to configure but which should not be part of the public API of these classes.
 */
@interface ARTClientOptions ()

/**
 Initial value is `nil`.
 */
@property (nullable, strong, nonatomic) NSString *channelNamePrefix;

@end

NS_ASSUME_NONNULL_END
