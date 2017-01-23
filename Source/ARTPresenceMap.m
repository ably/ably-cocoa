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
#import "ARTLog.h"

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

@implementation ARTPresenceMap {
    __weak ARTLog *_logger;
}

- (instancetype)initWithLogger:(ARTLog *)logger {
    self = [super init];
    if(self) {
        _logger = logger;
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

- (BOOL)add:(ARTPresenceMessage *)message {
    ARTPresenceMessage *latest = [self.recentMembers objectForKey:message.clientId];
    if ([self isNewestPresence:message comparingWith:latest]) {
        ARTPresenceMessage *messageCopy = [message copy];
        switch (message.action) {
            case ARTPresenceEnter:
            case ARTPresenceUpdate:
                messageCopy.action = ARTPresencePresent;
                break;
            case ARTPresenceLeave:
                if (self.syncInProgress) {
                    messageCopy.action = ARTPresenceAbsent;
                }
                break;
            default:
                break;
        }
        [self.recentMembers setObject:messageCopy forKey:message.clientId];
        return YES;
    }
    return NO;
}

- (BOOL)isNewestPresence:(nonnull ARTPresenceMessage *)received comparingWith:(ARTPresenceMessage *)latest  __attribute__((warn_unused_result)) {
    if (latest == nil) {
        return YES;
    }

    NSArray<NSString *> *receivedMessageIdParts = [received.id componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    if (receivedMessageIdParts.count != 3) {
        [_logger error:@"Received presence message id is invalid %@", received.id];
        return !received.timestamp ||
            [latest.timestamp timeIntervalSince1970] <= [received.timestamp timeIntervalSince1970];
    }
    NSString *receivedConnectionId = [receivedMessageIdParts objectAtIndex:0];
    NSInteger receivedMsgSerial = [[receivedMessageIdParts objectAtIndex:1] integerValue];
    NSInteger receivedIndex = [[receivedMessageIdParts objectAtIndex:2] integerValue];

    if ([receivedConnectionId isEqualToString:received.connectionId]) {
        NSArray<NSString *> *latestRegisteredIdParts = [latest.id componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        if (latestRegisteredIdParts.count != 3) {
            [_logger error:@"Latest registered presence message id is invalid %@", latest.id];
            return !received.timestamp ||
                [latest.timestamp timeIntervalSince1970] <= [received.timestamp timeIntervalSince1970];
        }
        NSInteger latestRegisteredMsgSerial = [[latestRegisteredIdParts objectAtIndex:1] integerValue];
        NSInteger latestRegisteredIndex = [[latestRegisteredIdParts objectAtIndex:2] integerValue];

        if (receivedMsgSerial > latestRegisteredMsgSerial) {
            return YES;
        }
        else if (receivedMsgSerial == latestRegisteredMsgSerial && receivedIndex > latestRegisteredIndex) {
            return YES;
        }
        return NO;
    }

    return !received.timestamp ||
        [latest.timestamp timeIntervalSince1970] <= [received.timestamp timeIntervalSince1970];
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
