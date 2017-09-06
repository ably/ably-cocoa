//
//  ARTPushAdmin.m
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushAdmin.h"
#import "ARTHttp.h"
#import "ARTPushDeviceRegistrations.h"
#import "ARTPushChannelSubscriptions.h"

@implementation ARTPushAdmin;

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _deviceRegistrations = [[ARTPushDeviceRegistrations alloc] init:rest];
        _channelSubscriptions = [[ARTPushChannelSubscriptions alloc] init:rest];
    }
    return self;
}

@end
