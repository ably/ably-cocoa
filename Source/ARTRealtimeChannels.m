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
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    if (self = [super init]) {
        _channels = [[ARTChannels alloc] initWithDelegate:self];
        _realtime = realtime;
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
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
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
} ART_TRY_OR_MOVE_TO_FAILED_END
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

@end
