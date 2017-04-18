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

- (instancetype)initWithId:(ARTDeviceId *)deviceId {
    if (self = [super init]) {
        _id = deviceId;
        _push = [[ARTDevicePushDetails alloc] init];
        _metadata = [[NSDictionary alloc] init];
    }
    return self;
}

@end
