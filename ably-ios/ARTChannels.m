//
//  ARTChannels.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannels.h"
#import "ARTChannels+Private.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTEncoder.h"
#import "ARTLog.h"

@implementation ARTChannelOptions

- (instancetype)initEncrypted:(ARTCipherParams *)cipherParams {
    if (self = [super init]) {
        self->_isEncrypted = YES;
        self->_cipherParams = cipherParams;
    }

    return self;
}

+ (instancetype)unencrypted {
    static id unencrypted;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unencrypted = [[ARTChannelOptions alloc] init];
    });

    return unencrypted;
}

@end

@implementation ARTChannel

- (instancetype)initWithName:(NSString *)name presence:(ARTPresence *)presence options:(nullable ARTChannelOptions *)options {
    if (self = [super init]) {
        _name = [name copy];
        _presence = presence;
        self.options = options;
    }

    return self;
}

- (void)setOptions:(ARTChannelOptions *)options {
    if (!options) {
        _options = [ARTChannelOptions unencrypted];
    } else {
        _options = options;
    }

    _payloadEncoder = [ARTJsonPayloadEncoder instance];
}

- (void)publish:(nullable id)payload callback:(ARTStatusCallback)callback {
    [self publish:payload name:nil callback:callback];
}

- (void)publish:(nullable id)payload name:(NSString *)name callback:(ARTStatusCallback)callback {
    [self publishMessage:[[ARTMessage alloc] initWithData:payload name:name] callback:callback];
}

- (void)publishMessages:(NSArray *)messages callback:(ARTStatusCallback)callback {
    messages = [messages artMap:^(ARTMessage *message) {
        return [message encode:_payloadEncoder];
    }];

    [self _postMessages:messages callback:callback];
}

- (void)publishMessage:(ARTMessage *)message callback:(ARTStatusCallback)callback {
    [self _postMessages:[message encode:_payloadEncoder] callback:callback];
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTStatus *, ARTPaginatedResult * __nullable))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)_postMessages:(id)payload callback:(ARTStatusCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end

@implementation ARTChannelCollection

- (instancetype)init {
    if (self = [super init]) {
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

- (ARTChannel *)_getChannel:(NSString *)channelName options:(nullable ARTChannelOptions *)options {
    ARTChannel *channel = self->_channels[channelName];
    if (!channel) {
        channel = [self _createChannelWithName:channelName options:options];
        [self->_channels setObject:channel forKey:channelName];
    } else if (options) {
        channel.options = options;
    }

    return channel;
}

- (ARTChannel *)_createChannelWithName:(NSString *)name options:(nullable ARTChannelOptions *)options {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
    return 0;
}

@end
