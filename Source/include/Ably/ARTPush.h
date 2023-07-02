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
 Ably will call the implementation of this method when the registration process is completed with failure.
 */
- (void)didAblyPushRegistrationFail:(nullable ARTErrorInfo *)error;

/**
 Ably will call the implementation of this method when the activation process is completed with success, so you can request other types of device tokens, such as `location`, `pushtotalk` etc.
 See https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns for possible values of `apns-push-type`.
 Before making request to Apple for alternative device token you should check whether you've already did this after application launch.
 */
- (void)shouldRequestAlternativeDeviceToken;

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

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-location-push-notifications) for details.
+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-location-push-notifications) for details.
+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-location-push-notifications) for details.
+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;

/// See [iOS push notifications tutorial](https://ably.com/tutorials/ios-location-push-notifications) for details.
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
@interface ARTPush : NSObject <ARTPushProtocol>

/**
 * An `ARTPushAdmin` object.
 */
@property (readonly) ARTPushAdmin *admin;

@end

// Utilities

@interface NSData (APNS)

- (NSString *)art_deviceTokenString;

@end

NS_ASSUME_NONNULL_END
