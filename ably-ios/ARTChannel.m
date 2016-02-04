//
//  ARTChannel.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannel+Private.h"

#import "ARTDataEncoder.h"
#import "ARTMessage.h"
#import "ARTChannelOptions.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTBaseMessage+Private.h"

@implementation ARTChannel

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options andLogger:(ARTLog *)logger {
    if (self = [super init]) {
        _name = name;
        self.options = options;
        _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:_options.cipherParams logger:logger];
        _logger = logger;
    }
    return self;
}

- (void)setOptions:(ARTChannelOptions *)options {
    if (!options) {
        _options = [ARTChannelOptions unencrypted];
    } else {
        _options = options;
    }
}

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self internalPostMessages:[self encodeMessageIfNeeded:[[ARTMessage alloc] initWithData:data name:name]]
                      callback:callback];
}

- (void)publish:(__GENERIC(NSArray, ARTMessage *) *)messages cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self internalPostMessages:[messages artMap:^id(ARTMessage *message) {
        return [self encodeMessageIfNeeded:message];
    }] callback:callback];
}

- (ARTMessage *)encodeMessageIfNeeded:(ARTMessage *)message  {
    if (!self.dataEncoder) {
        return message;
    }
    ARTStatus *status = [message encodeWithEncoder:self.dataEncoder output:&message];
    if (status.state != ARTStateOk) {
        [self.logger error:@"ARTChannel: error encoding data, status: %tu", status];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"message encoding failed" userInfo:nil];
    }
    return message;
}

- (BOOL)history:(ARTDataQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, NSError *))callback error:(NSError **)errorPtr {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
    return NO;
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
