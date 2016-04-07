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
        NSError *error;
        _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:_options.cipher error:&error];
        if (error != nil) {
            [logger warn:@"creating ARTDataEncoder: %@", error];
            _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:nil error:nil];
        }
        _logger = logger;
    }
    return self;
}

- (void)setOptions:(ARTChannelOptions *)options {
    if (!options) {
        _options = [[ARTChannelOptions alloc] initWithCipher:nil];
    } else {
        _options = options;
    }
}

- (void)publish:(NSString *)name data:(id)data {
    [self publish:name data:data callback:nil];
}

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self internalPostMessages:[self encodeMessageIfNeeded:[[ARTMessage alloc] initWithName:name data:data]]
                      callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    [self publish:name data:data clientId:clientId callback:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId callback:(void (^)(ARTErrorInfo * _Nullable))callback {
    [self internalPostMessages:[self encodeMessageIfNeeded:[[ARTMessage alloc] initWithName:name data:data clientId:clientId]]
                      callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [self publish:messages callback:nil];
}

- (void)publish:(__GENERIC(NSArray, ARTMessage *) *)messages callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self internalPostMessages:[messages artMap:^id(ARTMessage *message) {
        return [self encodeMessageIfNeeded:message];
    }] callback:callback];
}

- (ARTMessage *)encodeMessageIfNeeded:(ARTMessage *)message {
    if (!self.dataEncoder) {
        return message;
    }
    NSError *error = nil;
    message = [message encodeWithEncoder:self.dataEncoder error:&error];
    if (error != nil) {
        [self.logger error:@"ARTChannel: error encoding data: %@", error];
        [NSException raise:NSInvalidArgumentException format:@"ARTChannel: error encoding data: %@", error];
    }
    return message;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
