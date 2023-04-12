#import <Ably/ARTConnectionDetails.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnectionDetails ()

@property (readwrite, nonatomic, nullable) NSString *clientId;
@property (readwrite, nonatomic, nullable) NSString *connectionKey;

- (void)setMaxIdleInterval:(NSTimeInterval)seconds;

@end

NS_ASSUME_NONNULL_END
