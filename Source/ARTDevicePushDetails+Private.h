#import <Ably/ARTDevicePushDetails.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDevicePushDetails ()

- (NSString *)stateString;

+ (ARTPushState)stateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
