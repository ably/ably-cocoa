//
//  ARTPush.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTDeviceDetails.h"
#import "ARTTypes.h"

@interface ARTJsonObject : NSDictionary
@end

@interface ARTDeviceId : NSString
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

/// Publish a push notification.
- (void)publish:(NSDictionary<NSString *,NSString *> *)params jsonObject:(ARTJsonObject *)jsonObject;

#ifdef TARGET_OS_IPHONE
/// Register a device, including the information necessary to deliver push notifications to it.
- (void)activate:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable))callback;
/// Unregister a device.
- (void)deactivate:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceId * _Nullable, ARTErrorInfo * _Nullable))callback;
#endif

@end

NS_ASSUME_NONNULL_END
