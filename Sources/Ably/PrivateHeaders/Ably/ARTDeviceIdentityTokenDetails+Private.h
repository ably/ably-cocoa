#import <Ably/ARTDeviceIdentityTokenDetails.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDeviceIdentityTokenDetails ()

- (NSData *)archiveWithLogger:(nullable ARTInternalLog *)logger;

+ (nullable ARTDeviceIdentityTokenDetails *)unarchive:(NSData *)data withLogger:(nullable ARTInternalLog *)logger;

@end

NS_ASSUME_NONNULL_END
