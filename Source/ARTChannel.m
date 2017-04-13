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
    NSError *error;
    ARTMessage *messagesWithDataEncoded = [self encodeMessageIfNeeded:[[ARTMessage alloc] initWithName:name data:data] error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    [self publish:name data:data clientId:clientId callback:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId callback:(void (^)(ARTErrorInfo * _Nullable))callback {
    NSError *error;
    ARTMessage *messagesWithDataEncoded = [self encodeMessageIfNeeded:[[ARTMessage alloc] initWithName:name data:data clientId:clientId] error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [self publish:messages callback:nil];
}

- (void)publish:(__GENERIC(NSArray, ARTMessage *) *)messages callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSError *error;
    NSMutableArray<ARTMessage *> *messagesWithDataEncoded = [NSMutableArray new];
    for (ARTMessage *message in messages) {
        [messagesWithDataEncoded addObject:[self encodeMessageIfNeeded:message error:&error]];
    }
    if (error) {
        callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

- (ARTMessage *)encodeMessageIfNeeded:(ARTMessage *)message error:(NSError **)error {
    if (!self.dataEncoder) {
        return message;
    }
    NSError *e = nil;
    message = [message encodeWithEncoder:self.dataEncoder error:&e];
    if (e) {
        [self.logger error:@"ARTChannel: error encoding data: %@", e];
    }
    if (error) {
        *error = e;
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
