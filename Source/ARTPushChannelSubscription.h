#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the subscriptions of a device, or a group of devices sharing the same `clientId`, has to a channel in order to receive push notifications.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushChannelSubscription : NSObject

/**
 * BEGIN CANONICAL DOCSTRING
 * The unique ID of the device.
 * END CANONICAL DOCSTRING
 */
@property (nullable, nonatomic, readonly) NSString *deviceId;

/**
 * BEGIN CANONICAL DOCSTRING
 * The ID of the client the device, or devices are associated to.
 * END CANONICAL DOCSTRING
 */
@property (nullable, nonatomic, readonly) NSString *clientId;

/**
 * BEGIN CANONICAL DOCSTRING
 * The channel the push notification subscription is for.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) NSString *channel;

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * A static factory method to create a `ARTPushChannelSubscription` object for a channel and single device.
 *
 * @param deviceId The unique ID of the device.
 * @param channelName The channel name.
 *
 * @return An `ARTPushChannelSubscription` object.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithDeviceId:(NSString *)deviceId channel:(NSString *)channelName;

/**
 * BEGIN CANONICAL DOCSTRING
 * A static factory method to create a `ARTPushChannelSubscription` object for a channel and group of devices sharing the same `clientId`.
 *
 * @param clientId The ID of the client.
 * @param channelName The channel name.
 *
 * @return An `ARTPushChannelSubscription` object.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithClientId:(NSString *)clientId channel:(NSString *)channelName;

@end

NS_ASSUME_NONNULL_END
