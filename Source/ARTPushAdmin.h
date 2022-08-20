#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTPushDeviceRegistrations.h>
#import <Ably/ARTPushChannelSubscriptions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushAdminProtocol

- (instancetype)init NS_UNAVAILABLE;

/// Publish a push notification.
- (void)publish:(ARTPushRecipient *)recipient data:(ARTJsonObject *)data callback:(nullable ARTCallback)callback;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables the management of device registrations and push notification subscriptions. Also enables the publishing of push notifications to devices.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushAdmin : NSObject <ARTPushAdminProtocol>

@property (nonatomic, readonly) ARTPushDeviceRegistrations *deviceRegistrations;
@property (nonatomic, readonly) ARTPushChannelSubscriptions *channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
