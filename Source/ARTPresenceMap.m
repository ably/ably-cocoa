//
//  ARTPresenceMap.m
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTPresenceMap.h"
#import "ARTPresenceMessage.h"
#import "ARTEventEmitter.h"

typedef NS_ENUM(NSUInteger, ARTPresenceSyncState) {
    ARTPresenceSyncStarted, //ItemType: nil
    ARTPresenceSyncEnded, //ItemType: NSArray<ARTPresenceMessage *>*
    ARTPresenceSyncFailed //ItemType: ARTErrorInfo*
};

@interface ARTPresenceMap () {
    BOOL _syncStarted;
    ARTEventEmitter<NSNumber * /*ARTSyncState*/, id> *_syncEventEmitter;
}

@property (readwrite, strong, atomic) __GENERIC(NSMutableDictionary, NSString *, ARTPresenceMessage *) *recentMembers;

@end

@implementation ARTPresenceMap

- (id)init {
    self = [super init];
    if(self) {
        _recentMembers = [NSMutableDictionary dictionary];
        _syncStarted = false;
        _syncComplete = false;
        _syncEventEmitter = [[ARTEventEmitter alloc] init];
    }
    return self;
}

- (__GENERIC(NSDictionary, NSString *, ARTPresenceMessage *) *)getMembers {
    return self.recentMembers;
}

- (void)put:(ARTPresenceMessage *)message {
    ARTPresenceMessage *latest = [self.recentMembers objectForKey:message.clientId];
    if (!latest || !message.timestamp || [latest.timestamp timeIntervalSince1970] <= [message.timestamp timeIntervalSince1970]) {
        [self.recentMembers setObject:message forKey:message.clientId];
    }
}

- (void)clean {
    for (NSString *key in [self.recentMembers allKeys]) {
        ARTPresenceMessage *message = [self.recentMembers objectForKey:key];
        if (message.action == ARTPresenceAbsent || message.action == ARTPresenceLeave) {
            [self.recentMembers removeObjectForKey:key];
        }
    }
}

- (void)startSync {
    _recentMembers = [NSMutableDictionary dictionary];
    _syncStarted = true;
    _syncComplete = false;
    [_syncEventEmitter emit:[NSNumber numberWithInt:ARTPresenceSyncStarted] with:nil];
}

- (void)endSync {
    [self clean];
    _syncStarted = false;
    _syncComplete = true;
    [_syncEventEmitter emit:[NSNumber numberWithInt:ARTPresenceSyncEnded] with:[self.recentMembers allValues]];
    [_syncEventEmitter off];
}

- (void)failsSync:(ARTErrorInfo *)error {
    [self clean];
    _syncStarted = false;
    _syncComplete = true;
    [_syncEventEmitter emit:[NSNumber numberWithInt:ARTPresenceSyncFailed] with:error];
    [_syncEventEmitter off];
}

- (void)onceSyncEnds:(void (^)(NSArray<ARTPresenceMessage *> *))callback {
    if (self.syncInProgress) {
        [_syncEventEmitter once:[NSNumber numberWithInt:ARTPresenceSyncEnded] callback:callback];
    }
    else {
        callback([self.recentMembers allValues]);
    }
}

- (void)onceSyncFails:(void (^)(ARTErrorInfo *))callback {
    if (self.syncInProgress) {
        [_syncEventEmitter once:[NSNumber numberWithInt:ARTPresenceSyncFailed] callback:callback];
    }
}

- (BOOL)getSyncInProgress {
    return _syncStarted && !_syncComplete;
}

#pragma mark private

- (NSString *)memberKey:(ARTPresenceMessage *) message {
    return [NSString stringWithFormat:@"%@:%@", message.connectionId, message.clientId];
}

@end
