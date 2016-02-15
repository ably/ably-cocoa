//
//  ARTPresence.m
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPresence.h"

#import "ARTChannel.h"
#import "ARTDataQuery.h"

@implementation ARTPresenceQuery

- (instancetype)init {
    return [self initWithClientId:nil connectionId:nil];
}

- (instancetype)initWithClientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    return [self initWithLimit:100 clientId:clientId connectionId:connectionId];
}

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super init];
    if (self) {
        _limit = limit;
        _clientId = clientId;
        _connectionId = connectionId;
    }
    return self;
}

@end

@interface ARTPresence () {
    __weak ARTChannel *_channel;
}

@end

@implementation ARTPresence

- (instancetype) initWithChannel:(ARTChannel *) channel {
    if (self = [super init]) {
        _channel = channel;
    }
    return self;
}

- (ARTChannel *)getChannel {
    return _channel;
}

- (void)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, NSError *error))callback {
    [self get:[[ARTPresenceQuery alloc] init] cb:callback];
}

- (void)get:(ARTPresenceQuery *)query cb:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (NSError *)history:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    NSError *error = [[NSError alloc] init];
    [self historyWithError:&error callback:callback];
    return error;
}

- (NSError *)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    NSError *error = [[NSError alloc] init];
    [self history:query error:&error callback:callback];
    return error;
}

- (BOOL)historyWithError:(NSError *__autoreleasing  _Nullable *)errorPtr callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    return [self history:[[ARTDataQuery alloc] init] error:errorPtr callback:callback];
}

- (BOOL)history:(ARTDataQuery *)query error:(NSError **)errorPtr callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, NSError *))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
    return NO;
}

@end
