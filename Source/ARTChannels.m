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

NSString* (^__art_nullable ARTChannels_getChannelNamePrefix)();

@interface ARTChannels() {
    __weak ARTRest *_rest;
    __weak id<ARTChannelsDelegate> _delegate;
}

@end

@implementation ARTChannels

- (instancetype)initWithDelegate:(id)delegate {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (self = [super init]) {
        _channels = [[NSMutableDictionary alloc] init];
        _delegate = delegate;
    }
    return self;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSUInteger count = [self->_channels countByEnumeratingWithState:state objects:buffer count:len];
    for (NSUInteger i = 0; i < count; i++) {
        buffer[i] = self->_channels[buffer[i]];
    }
    return count;
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)exists:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return self->_channels[[self addPrefix:name]] != nil;
} ART_TRY_OR_REPORT_CRASH_END
}

- (id)get:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [self _getChannel:[self addPrefix:name] options:nil];
} ART_TRY_OR_REPORT_CRASH_END
}

- (id)get:(NSString *)name options:(ARTChannelOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [self _getChannel:[self addPrefix:name] options:options];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)release:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self->_channels removeObjectForKey:[self addPrefix:name]];
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    name = [self addPrefix:name];
    ARTRestChannel *channel = self->_channels[name];
    if (!channel) {
        channel = [_delegate makeChannel:name options:options];
        [self->_channels setObject:channel forKey:name];
    } else if (options) {
        channel.options = options;
    }
    return channel;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)addPrefix:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (ARTChannels_getChannelNamePrefix) {
        NSString *prefix = [NSString stringWithFormat:@"%@-", ARTChannels_getChannelNamePrefix()];
        if (![name hasPrefix:prefix]) {
            return [NSString stringWithFormat:@"%@-%@", ARTChannels_getChannelNamePrefix(), name];
        }
    }
    return name;
} ART_TRY_OR_REPORT_CRASH_END
}

@end
