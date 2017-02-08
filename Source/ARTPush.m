//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush.h"

@implementation ARTPush

#ifdef TARGET_OS_IPHONE
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"ARTPush %p %s: %@", self, __FUNCTION__, deviceToken);
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"ARTPush %p %s: %@", self, __FUNCTION__, error);
}
#endif

- (void)publish:(NSDictionary<NSString *,NSString *> *)params jsonObject:(ARTJsonObject *)jsonObject {

}

- (void)activate:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable))callback {

}

- (void)deactivate:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceId * _Nullable, ARTErrorInfo * _Nullable))callback {

}

@end
