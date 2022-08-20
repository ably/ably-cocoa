#import <Foundation/Foundation.h>
#import <Ably/ARTDeviceDetails.h>

@class ARTDeviceIdentityTokenDetails;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the device identity token and secret of a device. `LocalDevice` extends [`DeviceDetails`]{@link}.
 * END CANONICAL DOCSTRING
 */
@interface ARTLocalDevice : ARTDeviceDetails

/**
 * BEGIN CANONICAL DOCSTRING
 * A unique device identity token used to communicate with APNS or FCM.
 * END CANONICAL DOCSTRING
 */
@property (nullable, nonatomic, readonly) ARTDeviceIdentityTokenDetails *identityTokenDetails;

/**
 Device secret generated using random data with sufficient entropy. It's a sha256 digest encoded with base64.
 */
@property (strong, nullable, nonatomic) ARTDeviceSecret *secret;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
