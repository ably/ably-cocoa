//
//  ARTDeviceDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"

NSString *const ARTDevicePlatform = @"ios";
NSString *const ARTDeviceFormFactor = @"mobile";

@implementation ARTDeviceDetails

+ (instancetype)fromLocalDevice {
    return [[ARTDeviceDetails alloc] init];
}

- (instancetype)init {
    return [self initWithId:[[NSUUID new] UUIDString]];
}

- (instancetype)initWithId:(NSString *)id {
    if (self = [super init]) {
        _id = id;
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
