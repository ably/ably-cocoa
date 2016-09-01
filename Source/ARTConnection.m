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

@interface ARTConnection ()

@end

@implementation ARTConnection

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
    if (self == [super init]) {
        _eventEmitter = [[ARTEventEmitter alloc] init];
        _realtime = realtime;
        _serial = -1;
    }
    return self;
}

- (void)connect {
    [_realtime connect];
}

- (void)close {
    [_realtime close];
}

- (void)ping:(void (^)(ARTErrorInfo *))cb {
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

- (void)setErrorReason:(ARTErrorInfo *__art_nullable)errorReason {
    _errorReason = errorReason;
}

- (NSString *)getRecoveryKey {
    switch(self.state) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended: {
            NSString *recStr = self.key;
            if (recStr == nil) {
                return nil;
            }
            NSString *str = [recStr stringByAppendingString:[NSString stringWithFormat:@":%ld", (long)self.serial]];
            return str;
        } default:
            return nil;
    }
}

- (__GENERIC(ARTEventListener, ARTConnectionStateChange *) *)on:(ARTRealtimeConnectionState)event callback:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter on:[NSNumber numberWithInt:event] callback:cb];
}

- (__GENERIC(ARTEventListener, ARTConnectionStateChange *) *)on:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter on:cb];
}

- (__GENERIC(ARTEventListener, ARTConnectionStateChange *) *)once:(ARTRealtimeConnectionState)event callback:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter once:[NSNumber numberWithInt:event] callback:cb];
}

- (__GENERIC(ARTEventListener, ARTConnectionStateChange *) *)once:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter once:cb];
}

- (void)off {
    [_eventEmitter off];
}
- (void)off:(ARTRealtimeConnectionState)event listener:listener {
    [_eventEmitter off:[NSNumber numberWithInt:event] listener:listener];
}

- (void)off:(__GENERIC(ARTEventListener, ARTConnectionStateChange *) *)listener {
    [_eventEmitter off:listener];
}

- (void)emit:(ARTRealtimeConnectionState)event with:(ARTConnectionStateChange *)data {
    [_eventEmitter emit:[NSNumber numberWithInt:event] with:data];
}

- (ARTEventListener *)timed:(ARTEventListener *)listener deadline:(NSTimeInterval)deadline onTimeout:(void (^)())onTimeout {
    return [_eventEmitter timed:listener deadline:deadline onTimeout:onTimeout];
}

@end
