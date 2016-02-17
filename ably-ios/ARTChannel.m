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
#import "ARTDataQuery.h"

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

- (void)publish:(NSString *)name data:(id)data {
    [self publish:name data:data cb:nil];
}

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self internalPostMessages:[self encodeMessageIfNeeded:[[ARTMessage alloc] initWithName:name data:data]]
                      callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    [self publish:name data:data clientId:clientId cb:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId cb:(void (^)(ARTErrorInfo * _Nullable))callback {
    [self internalPostMessages:[self encodeMessageIfNeeded:[[ARTMessage alloc] initWithName:name data:data clientId:clientId]]
                      callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [self publish:messages cb:nil];
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

- (BOOL)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, NSError *))callback error:(NSError **)errorPtr {
    return [self history:[[ARTDataQuery alloc] init] callback:callback error:errorPtr];
}

- (BOOL)history:(ARTDataQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, NSError *))callback error:(NSError **)errorPtr {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
    return NO;
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
