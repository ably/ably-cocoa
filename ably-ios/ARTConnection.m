//
//  ARTConnection.m
//  ably
//
//  Created by Ricardo Pereira on 30/10/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnection.h"

#import "ARTRealtime+Private.h"
#import "ARTEventEmitter.h"

@interface ARTConnection () {
    // FIXME: temporary
    __weak ARTRealtime* _realtime;
}

@end

@implementation ARTConnection

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
    if (self == [super init]) {
        _realtime = realtime;
    }
    return self;
}

- (NSString *)getId {
    return _realtime.connectionId;
}

- (NSString *)getKey {
    return _realtime.connectionKey;
}

- (int64_t)getSerial {
    return _realtime.connectionSerial;
}

- (ARTRealtimeConnectionState)getState {
    return _realtime.state;
}

- (ARTEventEmitter *)getEventEmitter {
    return _realtime.eventEmitter;
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

@end
