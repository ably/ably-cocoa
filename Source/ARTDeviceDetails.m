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

@implementation ARTDeviceDetails

+ (instancetype)fromLocalDevice {
    return [[ARTDeviceDetails alloc] init];
    // TODO
}

- (instancetype)init {
    return [self initWithId:[[WSULID ulid] ULIDString]];
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
