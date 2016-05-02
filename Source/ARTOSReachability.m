//
//  ARTReachability.m
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "ARTOSReachability.h"

@implementation ARTOSReachability {
    ARTLog *_logger;
    NSString *_host;
    void (^_callback)(BOOL);
    SCNetworkReachabilityRef _reachabilityRef;
    NSMutableDictionary *_instances;
}

- (instancetype)initWithLogger:(ARTLog *)logger {
    self = [super self];
    if (self) {
        _logger = logger;
        if (ARTOSReachability_instances == nil) {
            _instances = [[NSMutableDictionary alloc] init];
            ARTOSReachability_instances = _instances;
        } else {
            _instances = ARTOSReachability_instances;
        }
    }
    return self;
}

__weak NSMutableDictionary *ARTOSReachability_instances;

static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    [(ARTOSReachability *)ARTOSReachability_instances[[NSValue valueWithPointer:target]] internalCallback:flags & kSCNetworkReachabilityFlagsReachable];
}

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback {
    [self off];
    _host = host;
    _callback = callback;

    _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
        [ARTOSReachability_instances setObject:self forKey:[NSValue valueWithPointer:_reachabilityRef]];
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            [_logger info:@"Reachability: started listening for host %@", _host];
        } else {
            [_logger warn:@"Reachability: failed starting listener for host %@", _host];
        }
    }
}

- (void)off {
    if (_reachabilityRef != NULL) {
        [ARTOSReachability_instances removeObjectForKey:[NSValue valueWithPointer:_reachabilityRef]];
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        [_logger info:@"Reachability: stopped listening for host %@", _host];
    }
    _callback = nil;
    _host = nil;
}

- (void)internalCallback:(BOOL)reachable {
    [_logger info:@"Reachability: host %@: %d", _host, reachable];
    _callback(reachable);
}

- (void)dealloc {
    [self off];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
    }
}

@end