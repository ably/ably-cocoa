#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTPushChannelSubscription;
@class ARTPaginatedResult;
@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushChannelSubscriptionsProtocol

- (instancetype)init NS_UNAVAILABLE;

- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(ARTCallback)callback;

- (void)listChannels:(ARTPaginatedTextCallback)callback;

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
