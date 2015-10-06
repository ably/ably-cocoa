//
//  ARTChannelCollection.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTChannelCollection.h"
#import "ARTChannelCollection+Private.h"

#import "ARTRest+Private.h"
#import "ARTChannel.h"
#import "ARTChannel+Private.h"
#import "ARTChannelOptions.h"
#import "ARTPresence.h"

@implementation ARTChannelCollection

- (instancetype)initWithRest:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _channels = [[NSMutableDictionary alloc] init];
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

- (BOOL)exists:(NSString *)channelName {
    return self->_channels[channelName] != nil;
}

- (ARTChannel *)get:(NSString *)channelName {
    return [self _getChannel:channelName options:nil];
}

- (ARTChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options {
    return [self _getChannel:channelName options:options];
}

- (void)releaseChannel:(ARTChannel *)channel {
    [self->_channels removeObjectForKey:channel.name];
}

- (ARTChannel *)_getChannel:(NSString *)channelName options:(ARTChannelOptions *)options {
    ARTChannel *channel = self->_channels[channelName];
    if (!channel) {
        channel = [[self.rest.channelClass alloc] initWithName:channelName rest:self.rest options:options];
        [self->_channels setObject:channel forKey:channelName];
    } else if (options) {
        channel.options = options;
    }
    return channel;
}

@end
