//
//  ARTRealtimeChannels.m
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRealtimeChannels+Private.h"
#import "ARTChannels+Private.h"
#import "ARTRealtimeChannel+Private.h"

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

- (id)makeChannel:(NSString *)name options:(ARTChannelOptions *)options {
    return [ARTRealtimeChannel channelWithRealtime:_realtime andName:name withOptions:options];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len {
    return [_channels countByEnumeratingWithState:state objects:buffer count:len];
}

- (ARTRealtimeChannel *)get:(NSString *)name {
    return [_channels get:name];
}

- (ARTRealtimeChannel *)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [_channels get:name options:options];
}

- (BOOL)exists:(NSString *)name {
    return [_channels exists:name];
}

- (void)release:(NSString *)name callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    ARTRealtimeChannel *channel;
    if ([self exists:name]) {
        channel = [self get:name];
    }
    if (channel) {
        [channel detach:^(ARTErrorInfo *errorInfo) {
            [channel off];
            [channel unsubscribe];
            [channel.presence unsubscribe];
            [_channels release:name];
            if (cb) cb(errorInfo);
        }];
    }
}

- (void)release:(NSString *)name {
    [self release:name callback:nil];
}

- (NSMutableDictionary *)getCollection {
    return _channels.channels;
}

@end
