#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTDeviceDetails;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushDeviceRegistrationsProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers or updates a `ARTDeviceDetails` object with Ably. Returns the new, or updated `ARTDeviceDetails` object.
 *
 * @param deviceDetails The `ARTDeviceDetails` object to create or update.
 *
 * @return A `ARTDeviceDetails` object.
 * END CANONICAL DOCSTRING
 */
- (void)save:(ARTDeviceDetails *)deviceDetails callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves the `ARTDeviceDetails` of a device registered to receive push notifications using its `deviceId`.
 *
 * @param deviceId The unique ID of the device.
 *
 * @return A `ARTDeviceDetails` object.
 * END CANONICAL DOCSTRING
 */
- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *_Nullable,  ARTErrorInfo *_Nullable))callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves all devices matching the filter `params` provided. Returns a `ARTPaginatedResult` object, containing an array of `ARTDeviceDetails` objects.
 *
 * @param params An object containing key-value pairs to filter devices by. Can contain `clientId`, `deviceId` and a `limit` on the number of devices returned, up to 1,000.
 *
 * @return A `ARTPaginatedResult` object containing an array of `ARTDeviceDetails` objects.
 * END CANONICAL DOCSTRING
 */
- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedDeviceDetailsCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Removes a device registered to receive push notifications from Ably using its `deviceId`.
 *
 * @param deviceId The unique ID of the device.
 * END CANONICAL DOCSTRING
 */
- (void)remove:(NSString *)deviceId callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Removes all devices registered to receive push notifications from Ably matching the filter `params` provided.
 *
 * @param params An object containing key-value pairs to filter devices by. Can contain `clientId` and `deviceId`.
 * END CANONICAL DOCSTRING
 */
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
