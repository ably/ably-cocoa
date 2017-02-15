//
//  ARTDeviceDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import <ULID/ULID.h>

NSString *const ARTDevicePlatform = @"ios";
NSString *const ARTDeviceFormFactor = @"mobile";

NSString *const ARTDeviceIdKey = @"ARTDeviceId";

@implementation ARTDeviceDetails

+ (instancetype)fromLocalDevice {
    NSString *deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceIdKey];
    if (!deviceId) {
        deviceId = [[WSULID ulid] ULIDString];
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:ARTDeviceIdKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return [[ARTDeviceDetails alloc] initWithId:deviceId];
}

- (instancetype)initWithId:(ARTDeviceId *)deviceId {
    if (self = [super init]) {
        _id = deviceId;
        _push = [[ARTDevicePushDetails alloc] init];
    }
    return self;
}

- (NSString *)platform {
    return ARTDevicePlatform;
}

- (NSString *)formFactor {
    return ARTDeviceFormFactor;
}

@end
