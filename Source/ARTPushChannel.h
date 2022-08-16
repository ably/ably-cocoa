#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>
#import <Ably/ARTHttp.h>
#import <Ably/ARTChannel.h>

@class ARTPushChannelSubscription;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushChannelProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Subscribes the device to push notifications for the channel.
 * END CANONICAL DOCSTRING
 */
- (void)subscribeDevice;
- (void)subscribeDevice:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Subscribes all devices associated with the current device's `clientId` to push notifications for the channel.
 * END CANONICAL DOCSTRING
 */
- (void)subscribeClient;
- (void)subscribeClient:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Unsubscribes the device from receiving push notifications for the channel.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribeDevice;
- (void)unsubscribeDevice:(nullable ARTCallback)callback;
- (void)unsubscribeClient;
- (void)unsubscribeClient:(nullable ARTCallback)callback;

- (BOOL)listSubscriptions:(NSStringDictionary *)params
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables devices to subscribe to push notifications for a channel.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushChannel : NSObject <ARTPushChannelProtocol>

@end

NS_ASSUME_NONNULL_END
