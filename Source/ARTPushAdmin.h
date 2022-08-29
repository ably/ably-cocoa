#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTPushDeviceRegistrations.h>
#import <Ably/ARTPushChannelSubscriptions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushAdminProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Sends a push notification directly to a device, or a group of devices sharing the same `clientId`.
 *
 * @param recipient A JSON object containing the recipient details using `clientId`, `deviceId` or the underlying notifications service.
 * @param data A JSON object containing the push notification payload.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)publish:(ARTPushRecipient *)recipient data:(ARTJsonObject *)data callback:(nullable ARTCallback)callback;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables the management of device registrations and push notification subscriptions. Also enables the publishing of push notifications to devices.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTPushAdmin : NSObject <ARTPushAdminProtocol>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTPushDeviceRegistrations` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) ARTPushDeviceRegistrations *deviceRegistrations;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTPushChannelSubscriptions` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) ARTPushChannelSubscriptions *channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
