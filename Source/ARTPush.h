//
//  ARTPush.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTPushAdmin.h"

@class ARTRest;
@class ARTRealtime;
@class ARTDeviceDetails;

// More context
typedef NSString ARTDeviceId;
typedef NSData ARTDeviceToken;
typedef NSString ARTUpdateToken;
typedef ARTJsonObject ARTPushRecipient;

#pragma mark ARTPushRegisterer interface

#ifdef TARGET_OS_IOS

@protocol ARTPushRegistererDelegate

- (void)didActivateAblyPush:(nullable ARTErrorInfo *)error;
- (void)didDeactivateAblyPush:(nullable ARTErrorInfo *)error;

@optional

- (void)didAblyPushRegistrationFail:(nullable ARTErrorInfo *)error;

- (void)ablyPushCustomRegister:(nullable ARTErrorInfo *)error deviceDetails:(nullable ARTDeviceDetails *)deviceDetails callback:(void (^ _Nonnull)(ARTUpdateToken * _Nonnull, ARTErrorInfo * _Nullable))callback;
- (void)ablyPushCustomDeregister:(nullable ARTErrorInfo *)error deviceId:(nullable ARTDeviceId *)deviceId callback:(void (^ _Nullable)(ARTErrorInfo * _Nullable))callback;

@end

#endif


#pragma mark ARTPush type

NS_ASSUME_NONNULL_BEGIN

@interface ARTPush : NSObject

@property (nonatomic, strong, readonly) ARTPushAdmin *admin;

- (instancetype)init NS_UNAVAILABLE;

/// Publish a push notification.
- (void)publish:(ARTPushRecipient *)recipient notification:(ARTJsonObject *)notification callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback;

#ifdef TARGET_OS_IOS

/// Push Registration token

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

/// Register a device, including the information necessary to deliver push notifications to it.
- (void)activate;

/// Unregister a device.
- (void)deactivate;
#endif

@end

NS_ASSUME_NONNULL_END
