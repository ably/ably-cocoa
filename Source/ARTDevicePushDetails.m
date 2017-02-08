//
//  ARTDevicePushDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 08/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDevicePushDetails.h"

NSString *const ARTDevicePushTransportType = @"apns";

@implementation ARTDevicePushDetails

- (NSString *)transportType {
    return ARTDevicePushTransportType;
}

@end
