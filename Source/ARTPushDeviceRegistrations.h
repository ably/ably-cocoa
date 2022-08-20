#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTDeviceDetails;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushDeviceRegistrationsProtocol

- (instancetype)init NS_UNAVAILABLE;

- (void)save:(ARTDeviceDetails *)deviceDetails callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves the [`DeviceDetails`]{@link DeviceDetails} of a device registered to receive push notifications using its `deviceId`.
 *
 * @param deviceId The unique ID of the device.
 *
 * @return A [`DeviceDetails`]{@link DeviceDetails} object.
 * END CANONICAL DOCSTRING
 */
- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *_Nullable,  ARTErrorInfo *_Nullable))callback;

- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedDeviceDetailsCallback)callback;

- (void)remove:(NSString *)deviceId callback:(ARTCallback)callback;
- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables the management of push notification registrations with Ably.
 * END CANONICAL DOCSTRING
 */
@interface ARTPushDeviceRegistrations : NSObject <ARTPushDeviceRegistrationsProtocol>

@end

NS_ASSUME_NONNULL_END
