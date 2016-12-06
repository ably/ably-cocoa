//
//  ARTDefault.m
//  ably
//
//  Created by vic on 01/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTDefault+Private.h"

@implementation ARTDefault

NSString *const ARTDefault_restHost = @"rest.ably.io";
NSString *const ARTDefault_realtimeHost = @"realtime.ably.io";
NSString *const ARTDefault_version = @"0.8";
NSString *const ARTDefault_libraryVersion = @"0.8.9";
NSString *const ARTDefault_platform = @"ios-";

static int _realtimeRequestTimeout = 10.0;
static int _connectionStateTtl = 60.0;

+ (NSArray*)fallbackHosts {
    return @[@"a.ably-realtime.com", @"b.ably-realtime.com", @"c.ably-realtime.com", @"d.ably-realtime.com", @"e.ably-realtime.com"];
}

+ (NSString*)restHost {
    return ARTDefault_restHost;
}

+ (NSString*)realtimeHost {
    return ARTDefault_realtimeHost;
}

+ (NSString *)version {
    return ARTDefault_version;
}

+ (int)port {
    return 80;
}

+ (int)tlsPort {
    return 443;
}

+ (NSTimeInterval)ttl {
    return 60 * 60;
}

+ (NSTimeInterval)connectionStateTtl {
    return _connectionStateTtl;
}

+ (NSTimeInterval)realtimeRequestTimeout {
    return _realtimeRequestTimeout;
}

+ (void)setRealtimeRequestTimeout:(NSTimeInterval)value {
    @synchronized (self) {
        _realtimeRequestTimeout = value;
    }
}

+ (void)setConnectionStateTtl:(NSTimeInterval)value {
    @synchronized (self) {
        _connectionStateTtl = value;
    }
}

+ (NSString *)libraryVersion {
    return [NSString stringWithFormat:@"%@%@", ARTDefault_platform, ARTDefault_libraryVersion];
}

@end
