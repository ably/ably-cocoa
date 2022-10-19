#import <Foundation/Foundation.h>
#import <Ably/ARTDeviceDetails.h>

@class ARTDeviceIdentityTokenDetails;

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains the device identity token and secret of a device. `ARTLocalDevice` extends `ARTDeviceDetails`.
 */
@interface ARTLocalDevice : ARTDeviceDetails

/**
 * A unique device identity token used to communicate with APNS.
 */
@property (nullable, nonatomic, readonly) ARTDeviceIdentityTokenDetails *identityTokenDetails;


/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
