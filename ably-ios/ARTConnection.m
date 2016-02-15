//
//  ARTConnection.m
//  ably
//
//  Created by Ricardo Pereira on 30/10/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnection+Private.h"

#import "ARTRealtime+Private.h"
#import "ARTEventEmitter.h"

@interface ARTConnection () {
    // FIXME: temporary
    __weak ARTEventEmitter* _eventEmitter;
}

@end

@implementation ARTConnection {
    __weak ARTRealtime *_realtime;
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
    if (self == [super init]) {
        _realtime = realtime;
        _eventEmitter = realtime.eventEmitter;
    }
    return self;
}

- (void)connect {
    [_realtime connect];
}

- (void)close {
    [_realtime close];
}

- (void)ping:(ARTRealtimePingCb)cb {
    [_realtime ping:cb];
}

- (void)setId:(NSString *)newId {
    _id = newId;
}

- (void)setKey:(NSString *)key {
    _key = key;
}

- (void)setSerial:(int64_t)serial {
    _serial = serial;
}

- (void)setState:(ARTRealtimeConnectionState)state {
    _state = state;
}

- (void)setErrorReason:(ARTErrorInfo * _Nullable)errorReason {
    _errorReason = errorReason;
}

- (NSString *)getRecoveryKey {
    switch(self.state) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended: {
            NSString *recStr = self.key;
            NSString *str = [recStr stringByAppendingString:[NSString stringWithFormat:@":%ld", (long)self.serial]];
            return str;
        } default:
            return nil;
    }
}

ART_EMBED_IMPLEMENTATION_EVENT_EMITTER(NSNumber *, ARTConnectionStateChange *)

@end
