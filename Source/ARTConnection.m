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
#import "ARTSentry.h"

@interface ARTConnection ()

@end

@implementation ARTConnection {
    _Nonnull dispatch_queue_t _queue;
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    if (self = [super init]) {
        _queue = dispatch_queue_create("io.ably.realtime.connection", DISPATCH_QUEUE_SERIAL);
        _eventEmitter = [[ARTEventEmitter alloc] initWithQueue:_queue];
        _realtime = realtime;
        _serial = -1;
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)connect {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime connect];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)close {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime close];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)ping:(void (^)(ARTErrorInfo *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime ping:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setId:(NSString *)newId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _id = newId;
    [ARTSentry setExtras:@"connectionId" value:newId];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setKey:(NSString *)key {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _key = key;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setSerial:(int64_t)serial {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _serial = serial;
    [ARTSentry setExtras:@"connectionSerial" value: [NSNumber numberWithLongLong:serial]];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setState:(ARTRealtimeConnectionState)state {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _state = state;
    [ARTSentry setExtras:@"connectionState" value:ARTRealtimeConnectionStateToStr(state)];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setErrorReason:(ARTErrorInfo *__art_nullable)errorReason {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _errorReason = errorReason;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)getRecoveryKey {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
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
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)on:(ARTRealtimeConnectionEvent)event callback:(void (^)(ARTConnectionStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_eventEmitter on:[ARTEvent newWithConnectionEvent:event] callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)on:(void (^)(ARTConnectionStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_eventEmitter on:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)once:(ARTRealtimeConnectionEvent)event callback:(void (^)(ARTConnectionStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_eventEmitter once:[ARTEvent newWithConnectionEvent:event] callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)once:(void (^)(ARTConnectionStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [_eventEmitter once:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)off {
    if (_realtime && _realtime.rest) {
        ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
            [_eventEmitter off];
        } ART_TRY_OR_MOVE_TO_FAILED_END
    } else {
        [_eventEmitter off];
    }
}
- (void)off:(ARTRealtimeConnectionEvent)event listener:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_eventEmitter off:[ARTEvent newWithConnectionEvent:event] listener:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)off:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_eventEmitter off:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_eventEmitter emit:[ARTEvent newWithConnectionEvent:event] with:data];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent (ConnectionEvent)

- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTRealtimeConnectionEvent%@", ARTRealtimeConnectionEventToStr(value)]];
}

+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value {
    return [[self alloc] initWithConnectionEvent:value];
}

@end
