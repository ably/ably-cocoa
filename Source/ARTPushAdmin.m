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

@implementation ARTPushAdmin {
    id<ARTHTTPAuthenticatedExecutor> _httpExecutor;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
        _deviceRegistrations = [[ARTPushDeviceRegistrations alloc] init:httpExecutor];
        _channelSubscriptions = [[ARTPushChannelSubscriptions alloc] init:httpExecutor];
    }
    return self;
}

@end
