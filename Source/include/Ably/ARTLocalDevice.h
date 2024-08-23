#import <Foundation/Foundation.h>
#import <Ably/ARTDeviceDetails.h>

@class ARTDeviceIdentityTokenDetails;

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains the device identity token and secret of a device. `ARTLocalDevice` extends `ARTDeviceDetails`.
 */
NS_SWIFT_SENDABLE
@interface ARTLocalDevice : ARTDeviceDetails

/**
 * A unique device identity token used to communicate with APNS.
 */
@property (nullable, nonatomic, readonly) ARTDeviceIdentityTokenDetails *identityTokenDetails;

/**
 * A unique device secret generated by the Ably SDK.
 */
@property (nullable, nonatomic) ARTDeviceSecret *secret;

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
