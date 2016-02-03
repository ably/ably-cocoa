//
//  ARTRestChannels.m
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRestChannels.h"
#import "ARTChannels+Private.h"

@interface ARTRestChannels ()

@property (weak, nonatomic) ARTRest *rest;

@end

@interface ARTRestChannels () <ARTChannelsDelegate>
@end

@implementation ARTRestChannels {
    ARTChannels *_channels;
}

- (instancetype)initWithRest:(ARTRest *)rest {
    if (self = [super init]) {
        _channels = [[ARTChannels alloc] initWithDelegate:self];
        _rest = rest;
    }
    return self;
}

- (id)makeChannel:(NSString *)channelName options:(ARTChannelOptions *)options {
    return [[ARTRestChannel alloc] initWithName:channelName withOptions:options andRest:_rest];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len {
    return [_channels countByEnumeratingWithState:state objects:buffer count:len];
}

- (ARTRestChannel *)get:(NSString *)channelName {
    return [_channels get:channelName];
}

- (ARTRestChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options {
    return [_channels get:channelName options:options];
}

- (BOOL)exists:(NSString *)channelName {
    return [_channels exists:channelName];
}

- (void)release:(NSString *)channelName {
    [_channels release:channelName];
}

@end
