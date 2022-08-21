#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the subscriptions of a device, or a group of devices sharing the same `clientId`, has to a channel in order to receive push notifications.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushChannelSubscription : NSObject

@property (nullable, nonatomic, readonly) NSString *deviceId;
@property (nullable, nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSString *channel;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDeviceId:(NSString *)deviceId channel:(NSString *)channelName;
- (instancetype)initWithClientId:(NSString *)clientId channel:(NSString *)channelName;

@end

NS_ASSUME_NONNULL_END
