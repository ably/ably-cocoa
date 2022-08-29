#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTPushChannelSubscription;
@class ARTPaginatedResult;
@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushChannelSubscriptionsProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Subscribes a device, or a group of devices sharing the same `clientId` to push notifications on a channel.
 *
 * @param channelSubscription An `ARTPushChannelSubscription` object.
 * @param callback A success or failure callback function.
 * END CANONICAL DOCSTRING
 */
- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves all channels with at least one device subscribed to push notifications. Returns a `ARTPaginatedResult` object, containing an array of channel names.
 *
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of channel names.
 * END CANONICAL DOCSTRING
 */
- (void)listChannels:(ARTPaginatedTextCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves all push channel subscriptions matching the filter `params` provided. Returns a `ARTPaginatedResult` object, containing an array of `ARTPushChannelSubscription` objects.
 *
 * @param params An object containing key-value pairs to filter subscriptions by. Can contain `channel`, `clientId`, `deviceId` and a `limit` on the number of devices returned, up to 1,000.
 *
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPushChannelSubscription` objects.
 * END CANONICAL DOCSTRING
 */
- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedPushChannelCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Unsubscribes a device, or a group of devices sharing the same `clientId` from receiving push notifications on a channel.
 *
 * @param subscription An `ARTPushChannelSubscription` object.
 * @param callback A success or failure callback function.
 * END CANONICAL DOCSTRING
 */
- (void)remove:(ARTPushChannelSubscription *)subscription callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Unsubscribes all devices from receiving push notifications on a channel that match the filter `params` provided.
 *
 * @param params An object containing key-value pairs to filter subscriptions by. Can contain `channel`, and optionally either `clientId` or `deviceId`.
 * @param callback A success or failure callback function.
 * END CANONICAL DOCSTRING
 */
- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables device push channel subscriptions.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushChannelSubscriptions : NSObject <ARTPushChannelSubscriptionsProtocol>

@end

NS_ASSUME_NONNULL_END
