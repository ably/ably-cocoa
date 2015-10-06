//
//  ARTChannel.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannel.h"
#import "ARTChannel+Private.h"

#import "ARTNSArray+ARTFunctional.h"
#import "ARTPayload.h"
#import "ARTMessage.h"
#import "ARTChannelOptions.h"

@implementation ARTChannel

- (instancetype)initWithName:(NSString *)name presence:(ARTPresence *)presence options:(ARTChannelOptions *)options {
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

- (void)publish:(id)payload callback:(ARTErrorCallback)callback {
    [self publish:payload name:nil callback:callback];
}

- (void)publish:(id)payload name:(NSString *)name callback:(ARTErrorCallback)callback {
    [self publishMessage:[[ARTMessage alloc] initWithData:payload name:name] callback:callback];
}

- (void)publishMessages:(NSArray *)messages callback:(ARTErrorCallback)callback {
    messages = [messages artMap:^(ARTMessage *message) {
        return [message encode:_payloadEncoder];
    }];

    [self _postMessages:messages callback:callback];
}

- (void)publishMessage:(ARTMessage *)message callback:(ARTErrorCallback)callback {
    [self _postMessages:[message encode:_payloadEncoder] callback:callback];
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult *, NSError *))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)_postMessages:(id)payload callback:(ARTErrorCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
