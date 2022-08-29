#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>

@class ARTDevicePushDetails;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the properties of a device registered for push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTDeviceDetails : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A unique ID generated by the device.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) ARTDeviceId *id;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The client ID the device is connected to Ably with.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nullable, nonatomic) NSString *clientId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The `ARTDevicePlatform` associated with the device. Describes the platform the device uses, such as `android` or `ios`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) NSString *platform;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The `ARTDeviceFormFactor` object associated with the device. Describes the type of the device, such as `phone` or `tablet`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) NSString *formFactor;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A JSON object of key-value pairs that contains metadata for the device.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *metadata;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The `ARTDevicePushDetails` object associated with the device. Describes the details of the push registration of the device.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) ARTDevicePushDetails *push;

- (instancetype)init;
- (instancetype)initWithId:(ARTDeviceId *)deviceId;

@end

NS_ASSUME_NONNULL_END
