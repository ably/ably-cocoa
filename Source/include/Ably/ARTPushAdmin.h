#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTPushDeviceRegistrations.h>
#import <Ably/ARTPushChannelSubscriptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTPushAdmin` is implemented.
 */
@protocol ARTPushAdminProtocol

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/**
 * Sends a push notification directly to a device, or a group of devices sharing the same `clientId`.
 *
 * @param recipient A JSON object containing the recipient details using `clientId`, `deviceId` or the underlying notifications service.
 * @param data A JSON object containing the push notification payload.
 * @param callback A success or failure callback function.
 */
- (void)publish:(ARTPushRecipient *)recipient data:(ARTJsonObject *)data callback:(nullable ARTCallback)callback;

@end

/**
 * Enables the management of device registrations and push notification subscriptions. Also enables the publishing of push notifications to devices.
 */
@interface ARTPushAdmin : NSObject <ARTPushAdminProtocol>

/**
 * An `ARTPushDeviceRegistrations` object.
 */
@property (nonatomic, readonly) ARTPushDeviceRegistrations *deviceRegistrations;

/**
 * An `ARTPushChannelSubscriptions` object.
 */
@property (nonatomic, readonly) ARTPushChannelSubscriptions *channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
