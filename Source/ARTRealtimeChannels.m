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

@interface ARTRealtimeChannels ()

@property (weak, nonatomic) ARTRealtime *realtime;

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
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [ARTRealtimeChannel channelWithRealtime:_realtime andName:name withOptions:options];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_channels countByEnumeratingWithState:state objects:buffer count:len];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTRealtimeChannel *)get:(NSString *)name {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_channels get:name];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTRealtimeChannel *)get:(NSString *)name options:(ARTChannelOptions *)options {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_channels get:name options:options];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)exists:(NSString *)name {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_channels exists:name];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)release:(NSString *)name callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_realtime.rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (![_channels _exists:name]) {
        if (cb) cb(nil);
        return;
    }

    ARTRealtimeChannel *channel = [_channels _get:name];
    [channel _detach:^(ARTErrorInfo *errorInfo) {
        [channel off];
        [channel unsubscribe];
        [channel.presence unsubscribe];

        // Only release if the stored channel now is the same as whne.
        // Otherwise, subsequent calls to this release method race, and
        // a new channel, created between the first call releases the stored
        // one and the second call's detach callback is called, can be
        // released unwillingly.
        if ([_channels _exists:name] && [_channels _get:name] == channel) {
            [_channels _release:name];
        }

        if (cb) cb(errorInfo);
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)release:(NSString *)name {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self release:name callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSMutableDictionary *)getCollection {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _channels.channels;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (id<NSFastEnumeration>)getNosyncIterable {
    return [_channels getNosyncIterable];
}

- (ARTRealtimeChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options {
    return [_channels _getChannel:name options:options];
}

@end
