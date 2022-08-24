#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTRest;
@class ARTRealtime;
@class ARTPushAdmin;
@class ARTDeviceDetails;
@class ARTDeviceIdentityTokenDetails;

NS_ASSUME_NONNULL_BEGIN

#pragma mark ARTPushRegisterer interface

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


#pragma mark ARTPush type

@protocol ARTPushProtocol

- (instancetype)init NS_UNAVAILABLE;

#if TARGET_OS_IOS

/// Push Registration token

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

/**
 * BEGIN CANONICAL DOCSTRING
 * Activates the device for push notifications with FCM or APNS, obtaining a unique identifier from them. Subsequently registers the device with Ably and stores the `deviceIdentityToken` in local storage.
 *
 * @param ErrorInfo Describes why the activation was unsuccessful as an `ARTErrorInfo` object.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Activating a device for push notifications and registering it with Ably. The registration process can be performed entirely from the device or from your own server using the optional `ablyPushCustomRegister:deviceDetails:callback` method.
 * END LEGACY DOCSTRING
 */
- (void)activate;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deactivates the device from receiving push notifications with Ably and FCM or APNS.
 *
 * @param ErrorInfo Describes why the deactivation was unsuccessful as an `ARTErrorInfo` object.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Deactivating a device for push notifications and unregistering it with Ably. The unregistration process can be performed entirely from the device or from your own server using the optional `ablyPushCustomDeregister:deviceId:callback` method.
 * END LEGACY DOCSTRING
 */
- (void)deactivate;

#endif

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a device to be registered and deregistered from receiving push notifications.
 * END CANONICAL DOCSTRING
 */
@interface ARTPush : NSObject <ARTPushProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * A `ARTPushAdmin` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTPushAdmin *admin;

@end

NS_ASSUME_NONNULL_END
