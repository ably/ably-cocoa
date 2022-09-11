#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>
#import <Ably/ARTHttp.h>
#import <Ably/ARTChannel.h>

@class ARTPushChannelSubscription;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTPushChannel` is implemented.
 */
@protocol ARTPushChannelProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Subscribes the device to push notifications for the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)subscribeDevice;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Subscribes the device to push notifications for the channel.
 *
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)subscribeDevice:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Subscribes all devices associated with the current device's `clientId` to push notifications for the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)subscribeClient;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Subscribes all devices associated with the current device's `clientId` to push notifications for the channel.
 *
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)subscribeClient:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Unsubscribes the device from receiving push notifications for the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribeDevice;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Unsubscribes the device from receiving push notifications for the channel.
 *
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribeDevice:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Unsubscribes all devices associated with the current device's `clientId` from receiving push notifications for the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribeClient;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Unsubscribes all devices associated with the current device's `clientId` from receiving push notifications for the channel.
 *
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribeClient:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves all push subscriptions for the channel. Subscriptions can be filtered using a `params` object. Returns a `ARTPaginatedResult` object containing an array of `ARTPushChannelSubscription` objects.
 *
 * @param params An object containing key-value pairs to filter subscriptions by. Can contain `clientId`, `deviceId` or a combination of both if `concatFilters` is set to `true`, and a `limit` on the number of subscriptions returned, up to 1,000.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPushChannelSubscription` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)listSubscriptions:(NSStringDictionary *)params
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables devices to subscribe to push notifications for a channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTPushChannel : NSObject <ARTPushChannelProtocol>

@end

NS_ASSUME_NONNULL_END
