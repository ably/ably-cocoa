//
//  ARTChannel.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannel+Private.h"

#import "ARTPayload.h"
#import "ARTMessage.h"
#import "ARTChannelOptions.h"
#import "ARTNSArray+ARTFunctional.h"

@implementation ARTChannel

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options {
    if (self = [super init]) {
        _name = name;
        _options = options;
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

- (void)publish:(id)data callback:(ARTErrorCallback)callback {
    [self publish:data name:nil callback:callback];
}

- (void)publish:(id)data name:(NSString *)name callback:(ARTErrorCallback)callback {
    [self publishMessage:[[ARTMessage alloc] initWithData:data name:name] callback:callback];
}

- (void)publishMessages:(NSArray *)messages callback:(ARTErrorCallback)callback {
    messages = [messages artMap:^(ARTMessage *message) {
        return [message encode:_payloadEncoder];
    }];

    [self internalPostMessages:messages callback:callback];
}

- (void)publishMessage:(ARTMessage *)message callback:(ARTErrorCallback)callback {
    [self internalPostMessages:[message encode:_payloadEncoder] callback:callback];
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult *, NSError *))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)internalPostMessages:(id)data callback:(ARTErrorCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
