#import <Ably/ARTDeviceIdentityTokenDetails.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDeviceIdentityTokenDetails ()

- (NSData *)archiveWithLogger:(nullable ARTLog *)logger;

+ (nullable ARTDeviceIdentityTokenDetails *)unarchive:(NSData *)data withLogger:(nullable ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
