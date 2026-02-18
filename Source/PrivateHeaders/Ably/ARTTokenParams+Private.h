#import <Ably/ARTTokenParams.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTTokenParams (Private)

- (ARTTokenRequest *)sign:(NSString *)key;
- (ARTTokenRequest *)sign:(NSString *)key withNonce:(NSString *)nonce;

@end

NS_ASSUME_NONNULL_END
