//
//  ARTRealtimeChannels.m
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRealtimeChannels.h"
#import "ARTChannels+Private.h"

@interface ARTRealtimeChannels ()

@property (weak, nonatomic) ARTRealtime *realtime;

@end

@interface ARTRealtimeChannels () <ARTChannelsDelegate>
@end

@implementation ARTRealtimeChannels {
    ARTChannels *_channels;
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
    if (self = [super init]) {
        _channels = [[ARTChannels alloc] initWithDelegate:self];
        _realtime = realtime;
    }
    return self;
}

- (id)makeChannel:(NSString *)channelName options:(ARTChannelOptions *)options {
    return [ARTRealtimeChannel channelWithRealtime:_realtime andName:channelName withOptions:options];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len {
    return [_channels countByEnumeratingWithState:state objects:buffer count:len];
}

- (ARTRealtimeChannel *)get:(NSString *)channelName {
    return [_channels get:channelName];
}

- (ARTRealtimeChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options {
    return [_channels get:channelName options:options];
}

- (BOOL)exists:(NSString *)channelName {
    return [_channels exists:channelName];
}

- (void)release:(NSString *)channelName {
    [_channels release:channelName];
}

@end
