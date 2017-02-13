//
//  ARTPush.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTRest;
@class ARTDeviceDetails;

@interface ARTJsonObject : NSDictionary
@end

@interface ARTDeviceId : NSString
@end

@interface ARTDeviceToken : NSData
@end

@interface ARTUpdateToken : NSString
@end


#pragma mark ARTPushNotifications interface

#ifdef TARGET_OS_IPHONE
@protocol ARTPushNotifications<NSObject>
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error;
@end
#endif


#pragma mark ARTPush type

NS_ASSUME_NONNULL_BEGIN

#ifdef TARGET_OS_IPHONE
@interface ARTPush : NSObject <ARTPushNotifications>
#else
@interface ARTPush : NSObject
#endif

@property (nonatomic, readonly) ARTDeviceDetails *device;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(ARTRest *)rest;

/// Publish a push notification.
- (void)publish:(id<ARTPushRecipient>)recipient jsonObject:(ARTJsonObject *)jsonObject;

#ifdef TARGET_OS_IPHONE
/// Register a device, including the information necessary to deliver push notifications to it.
- (void)activate;
- (void)activate:(ARTDeviceDetails *)deviceDetails;
- (void)activate:(ARTDeviceDetails *)deviceDetails registerCallback:(nullable ARTUpdateToken* (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable))registerCallback;
/// Unregister a device.
- (void)deactivate:(ARTDeviceId *)deviceId;
- (void)deactivate:(ARTDeviceId *)deviceId deregisterCallback:(nullable void (^)(ARTDeviceId * _Nullable, ARTErrorInfo * _Nullable))deregisterCallback;
#endif

@end

NS_ASSUME_NONNULL_END
