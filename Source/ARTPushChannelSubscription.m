//
//  ARTPushChannelSubscription.m
//  Ably
//
//  Created by Ricardo Pereira on 15/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushChannelSubscription.h"

@implementation ARTPushChannelSubscription

- (instancetype)initWithDeviceId:(NSString *)deviceId channel:(NSString *)channelName {
    if (self = [super init]) {
        _deviceId = deviceId;
        _channel = channelName;
    }
    return self;
}

- (instancetype)initWithClientId:(NSString *)clientId channel:(NSString *)channelName {
    if (self = [super init]) {
        _clientId = clientId;
        _channel = channelName;
    }
    return self;
}

@end
