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

NS_ASSUME_NONNULL_BEGIN

@interface ARTPush : NSObject

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
