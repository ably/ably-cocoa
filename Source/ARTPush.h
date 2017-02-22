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

@protocol ARTHTTPAuthenticatedExecutor;

// More context
typedef NSString ARTDeviceId;
typedef NSData ARTDeviceToken;
typedef NSString ARTUpdateToken;
typedef ARTJsonObject ARTPushRecipient;


#pragma mark ARTPushNotifications interface

#ifdef TARGET_OS_IOS
@protocol ARTPushNotifications<NSObject>
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error;
@end
#endif


#pragma mark ARTPush type

NS_ASSUME_NONNULL_BEGIN

#ifdef TARGET_OS_IOS
@interface ARTPush : NSObject <ARTPushNotifications>
#else
@interface ARTPush : NSObject
#endif

@property (nonatomic, readonly) ARTDeviceDetails *device;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor;

/// Publish a push notification.
- (void)publish:(ARTPushRecipient *)recipient jsonObject:(ARTJsonObject *)jsonObject;

#ifdef TARGET_OS_IOS
/// Register a device, including the information necessary to deliver push notifications to it.
- (void)activate;
- (void)activateWithRegisterCallback:(void (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable,  void (^ _Nullable)(ARTUpdateToken * _Nullable, ARTErrorInfo * _Nullable)))registerCallback;
/// Unregister a device.
- (void)deactivate;
- (void)deactivateWithDeregisterCallback:(void (^)(ARTDeviceId * _Nullable, ARTErrorInfo * _Nullable, void (^ _Nullable)(ARTErrorInfo * _Nullable)))deregisterCallback;
#endif

@end

NS_ASSUME_NONNULL_END
