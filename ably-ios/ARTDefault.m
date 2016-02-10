//
//  ARTDefault.m
//  ably
//
//  Created by vic on 01/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTDefault+Private.h"

@implementation ARTDefault

NSString *const DefaultRestHost = @"rest.ably.io";
NSString *const DefaultRealtimeHost = @"realtime.ably.io";

static int _realtimeRequestTimeout = 10.0;

+ (NSArray*)fallbackHosts {
    return @[@"A.ably-realtime.com", @"B.ably-realtime.com", @"C.ably-realtime.com", @"D.ably-realtime.com", @"E.ably-realtime.com"];
}

+ (NSString*)restHost {
    return DefaultRestHost;
}

+ (NSString*)realtimeHost {
    return DefaultRealtimeHost;
}

+ (int)TLSPort {
    return 443;
}

+ (NSTimeInterval)ttl {
    return 60 * 60;
}

+ (NSTimeInterval)connectTimeout {
    return 15;
}

+ (NSTimeInterval)connectionStateTtl {
    return 60.0;
}

+ (NSTimeInterval)realtimeRequestTimeout {
    return _realtimeRequestTimeout;
}

+ (void)setRealtimeRequestTimeout:(NSTimeInterval)value {
    @synchronized (self) {
        _realtimeRequestTimeout = value;
    }
}

@end
