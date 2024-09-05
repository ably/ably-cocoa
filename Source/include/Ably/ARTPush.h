#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTRest;
@class ARTRealtime;
@class ARTPushAdmin;
@class ARTDeviceDetails;
@class ARTDeviceIdentityTokenDetails;

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS

/**
 The interface for handling Push activation/deactivation-related actions.
 */
@protocol ARTPushRegistererDelegate

/**
 Ably will call the implementation of this method when the activation process is completed with success or with failure.
 */
- (void)didActivateAblyPush:(nullable ARTErrorInfo *)error;

/**
 Ably will call the implementation of this method when the deactivation process is completed with success or with failure.
 */
- (void)didDeactivateAblyPush:(nullable ARTErrorInfo *)error;

@optional

/**
 Ably will call the implementation of this method when the token update process is completed with success or with failure.
 */
- (void)didUpdateAblyPush:(nullable ARTErrorInfo *)error;

/**
 Same as `didUpdateAblyPush:`, but called only in case of failure for backward compatibility.
 */
- (void)didAblyPushRegistrationFail:(nullable ARTErrorInfo *)error;

/**
 Optional method.
 If you want to activate devices from your server, then you should implement this method (including the `ablyPushCustomDeregister:deviceId:callback` method) where the network request completion should call the callback argument to continue with the registration process.
 */
- (void)ablyPushCustomRegister:(ARTErrorInfo * _Nullable)error deviceDetails:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTDeviceIdentityTokenDetails * _Nullable, ARTErrorInfo * _Nullable))callback;

/**
 Optional method.
 If you want to deactivate devices from your server, then you should implement this method (including the `ablyPushCustomRegister:deviceDetails:callback` method) where the network request completion should call the callback argument to continue with the registration process.
 */
- (void)ablyPushCustomDeregister:(ARTErrorInfo * _Nullable)error deviceId:(ARTDeviceId *)deviceId callback:(ARTCallback)callback;

@end

#endif

/**
 The protocol upon which the `ARTPush` is implemented.
 */
@protocol ARTPushProtocol

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

#if TARGET_OS_IOS

// Push Registration token

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-push-notifications#step7-register-push-ably) for details.
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-push-notifications#step7-register-push-ably) for details.
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-push-notifications#step7-register-push-ably) for details.
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-push-notifications#step7-register-push-ably) for details.
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

// Location Push Registration token

/// Registers location device token within Ably service. You obtain it by calling `CLLocationManager.startMonitoringLocationPushes(completion:)`.
+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;

/// Registers location device token within Ably service. You obtain it by calling `CLLocationManager.startMonitoringLocationPushes(completion:)`.
+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

/// Call this method if you got an error calling `CLLocationManager.startMonitoringLocationPushes(completion:)`.
+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;

/// Call this method if you got an error calling `CLLocationManager.startMonitoringLocationPushes(completion:)`.
+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

/**
 * Activates the device for push notifications with APNS, obtaining a unique identifier from it. Subsequently registers the device with Ably and stores the `ARTLocalDevice.identityTokenDetails` in local storage.
 * You should implement `-[ARTPushRegistererDelegate didActivateAblyPush:]` to handle success or failure of this operation.
 */
- (void)activate;

/**
 * Deactivates the device from receiving push notifications with Ably.
 * You should implement `-[ARTPushRegistererDelegate didDeactivateAblyPush:]` to handle success or failure of this operation.
 */
- (void)deactivate;

#endif

@end

/**
 * Enables a device to be registered and deregistered from receiving push notifications.
 */
NS_SWIFT_SENDABLE
@interface ARTPush : NSObject <ARTPushProtocol>

/**
 * An `ARTPushAdmin` object.
 */
@property (readonly) ARTPushAdmin *admin;

@end

NS_ASSUME_NONNULL_END
