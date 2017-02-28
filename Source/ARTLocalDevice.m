//
//  ARTLocalDevice.m
//  Ably
//
//  Created by Ricardo Pereira on 28/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTLocalDevice.h"
#import "ARTDevicePushDetails.h"
#import "ARTPush.h"
#import <ULID/ULID.h>

@implementation ARTLocalDevice

- (instancetype)init {
    NSString *deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceIdKey];
    if (!deviceId) {
        deviceId = [[ULID new] ulidString];
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:ARTDeviceIdKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (self = [super initWithId:deviceId]) {
        self.updateToken = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceUpdateTokenKey];
    }
    return self;
}

+ (ARTLocalDevice *)local {
    static dispatch_once_t once;
    static id localDevice;
    dispatch_once(&once, ^{
        localDevice = [[ARTLocalDevice alloc] init];
    });
    return localDevice;
}

- (ARTDeviceToken *)registrationToken {
    return self.push.deviceToken;
}

- (void)resetId {

}

- (void)resetUpdateToken:(void (^)(ARTErrorInfo *error))callback {

}

@end
