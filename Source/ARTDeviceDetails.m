//
//  ARTDeviceDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"

@implementation ARTDeviceDetails

- (instancetype)init {
    if (self = [super init]) {
        _push = [[ARTDevicePushDetails alloc] init];
        _metadata = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithId:(ARTDeviceId *)deviceId {
    if (self = [self init]) {
        _id = deviceId;
    }
    return self;
}

@end
