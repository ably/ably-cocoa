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

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [NSMutableArray array];

    if (self.clientId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"clientId" value:self.clientId]];
    }
    if (self.connectionId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"connectionId" value:self.connectionId]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%lu", (unsigned long)self.limit]]];

    return items;
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


- (void)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback {
    [self get:[[ARTPresenceQuery alloc] init] callback:callback error:nil];
}

- (BOOL)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
    return [self get:[[ARTPresenceQuery alloc] init] callback:callback error:errorPtr];
}

- (BOOL)get:(ARTPresenceQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, ARTErrorInfo * _Nullable))callback error:(NSError **)errorPtr {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
    return false;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback {
    [self history:[[ARTDataQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTDataQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
    return NO;
}

@end
