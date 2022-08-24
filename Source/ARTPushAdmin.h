#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTPushDeviceRegistrations.h>
#import <Ably/ARTPushChannelSubscriptions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushAdminProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Sends a push notification directly to a device, or a group of devices sharing the same `clientId`.
 *
 * @param recipient A JSON object containing the recipient details using `clientId`, `deviceId` or the underlying notifications service.
 * @param data A JSON object containing the push notification payload.
 * END CANONICAL DOCSTRING
 */
- (void)publish:(ARTPushRecipient *)recipient data:(ARTJsonObject *)data callback:(nullable ARTCallback)callback;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables the management of device registrations and push notification subscriptions. Also enables the publishing of push notifications to devices.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushAdmin : NSObject <ARTPushAdminProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`PushDeviceRegistrations`]{@link PushDeviceRegistrations} object.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) ARTPushDeviceRegistrations *deviceRegistrations;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`PushChannelSubscriptions`]{@link PushChannelSubscriptions} object.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) ARTPushChannelSubscriptions *channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
