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
 * Subscribes a device, or a group of devices sharing the same `clientId` to push notifications on a channel. Returns a [`PushChannelSubscription`]{@link PushChannelSubscription} object.
 *
 * @param channelSubscription A [`PushChannelSubscription`]{@link PushChannelSubscription} object.
 *
 * @return A [`PushChannelSubscription`]{@link PushChannelSubscription} object describing the new or updated subscriptions.
 * END CANONICAL DOCSTRING
 */
- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(ARTCallback)callback;

- (void)listChannels:(ARTPaginatedTextCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves all push channel subscriptions matching the filter `params` provided. Returns a [`PaginatedResult`]{@link PaginatedResult} object, containing an array of [`PushChannelSubscription`]{@link PushChannelSubscription} objects.
 *
 * @param params An object containing key-value pairs to filter subscriptions by. Can contain `channel`, `clientId`, `deviceId` and a `limit` on the number of devices returned, up to 1,000.
 *
 * @return A [`PaginatedResult`]{@link PaginatedResult} object containing an array of [`PushChannelSubscription`]{@link PushChannelSubscription} objects.
 * END CANONICAL DOCSTRING
 */
- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedPushChannelCallback)callback;

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(ARTCallback)callback;
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
