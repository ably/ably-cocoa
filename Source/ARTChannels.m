//
//  ARTChannels.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTChannels+Private.h"

#import "ARTRest+Private.h"
#import "ARTChannel+Private.h"
#import "ARTChannelOptions.h"
#import "ARTRestChannel.h"

@interface ARTChannels() {
    __weak ARTRest *_rest;
    __weak id<ARTChannelsDelegate> _delegate;
}

@end

@implementation ARTChannels

- (instancetype)initWithDelegate:(id)delegate {
    if (self = [super init]) {
        _channels = [[NSMutableDictionary alloc] init];
        _delegate = delegate;
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    NSUInteger count = [self->_channels countByEnumeratingWithState:state objects:buffer count:len];
    for (NSUInteger i = 0; i < count; i++) {
        buffer[i] = self->_channels[buffer[i]];
    }
    return count;
}

- (BOOL)exists:(NSString *)name {
    return self->_channels[name] != nil;
}

- (id)get:(NSString *)name {
    return [self _getChannel:name options:nil];
}

- (id)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [self _getChannel:name options:options];
}

- (void)release:(NSString *)name {
    [self->_channels removeObjectForKey:name];
}

- (ARTRestChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options {
    ARTRestChannel *channel = self->_channels[name];
    if (!channel) {
        channel = [_delegate makeChannel:name options:options];
        [self->_channels setObject:channel forKey:name];
    } else if (options) {
        channel.options = options;
    }
    return channel;
}

@end
