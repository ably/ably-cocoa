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
#import "ARTRealtime+Private.h"
#import "ARTRealtimePresence+Private.h"

@interface ARTRealtimeChannels ()

@property (weak, nonatomic) ARTRealtime *realtime; // weak because realtime owns self

@end

@interface ARTRealtimeChannels () <ARTChannelsDelegate>
@end

@implementation ARTRealtimeChannels {
    ARTChannels *_channels;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    if (self = [super init]) {
        _realtime = realtime;
        _userQueue = _realtime.rest.userQueue;
        _queue = _realtime.rest.queue;
        _channels = [[ARTChannels alloc] initWithDelegate:self dispatchQueue:_queue];
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
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
    name = [ARTChannels addPrefix:name];

    if (cb) {
        void (^userCallback)(ARTErrorInfo *error) = cb;
        cb = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    if (![self->_channels _exists:name]) {
        if (cb) cb(nil);
        return;
    }
    
    ARTRealtimeChannel *channel = [self->_channels _get:name];
    [channel _detach:^(ARTErrorInfo *errorInfo) {
        [channel close];
        [self->_channels _remove:name];

        if (cb) cb(errorInfo);
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)release:(NSString *)name {
    [self release:name callback:nil];
}

- (NSMutableDictionary *)getCollection {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _channels.channels;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (id<NSFastEnumeration>)getNosyncIterable {
    return [_channels getNosyncIterable];
}

- (ARTRealtimeChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options addPrefix:(BOOL)addPrefix {
    return [_channels _getChannel:name options:options addPrefix:addPrefix];
}

- (void)flush {
    NSMutableArray<NSString *> *toRemove = [[NSMutableArray alloc] init];
    for (ARTRealtimeChannel *channel in [self getNosyncIterable]) {
        [channel close];
        [toRemove addObject:channel.name];
    }
    for (NSString *channelName in toRemove) {
        [_channels _remove:channelName];
    }
}

@end
