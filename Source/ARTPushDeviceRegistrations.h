#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTDeviceDetails;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTPushDeviceRegistrations` is implemented.
 */
@protocol ARTPushDeviceRegistrationsProtocol

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Registers or updates a `ARTDeviceDetails` object with Ably.
 *
 * @param deviceDetails The `ARTDeviceDetails` object to create or update.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)save:(ARTDeviceDetails *)deviceDetails callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves the `ARTDeviceDetails` of a device registered to receive push notifications using its `deviceId`.
 *
 * @param deviceId The unique ID of the device.
 * @param callback A callback for receiving the `ARTDeviceDetails` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *_Nullable,  ARTErrorInfo *_Nullable))callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves all devices matching the filter `params` provided. Returns a `ARTPaginatedResult` object, containing an array of `ARTDeviceDetails` objects.
 *
 * @param params An object containing key-value pairs to filter devices by. Can contain `clientId`, `deviceId` and a `limit` on the number of devices returned, up to 1,000.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTDeviceDetails` objects.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedDeviceDetailsCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Removes a device registered to receive push notifications from Ably using its `deviceId`.
 *
 * @param deviceId The unique ID of the device.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)remove:(NSString *)deviceId callback:(ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Removes all devices registered to receive push notifications from Ably matching the filter `params` provided.
 *
 * @param params An object containing key-value pairs to filter devices by. Can contain `clientId` and `deviceId`.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables the management of push notification registrations with Ably.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * @see See `ARTPushDeviceRegistrationsProtocol` for details.
 */
@interface ARTPushDeviceRegistrations : NSObject <ARTPushDeviceRegistrationsProtocol>

@end

NS_ASSUME_NONNULL_END
