#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "ARTOSReachability.h"

@interface ARTOSReachability ()
- (void)internalCallback:(BOOL)reachable;
@end

/// Global callback for network state changes
static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    ARTOSReachability *reachability = (__bridge ARTOSReachability *)info;
    BOOL reachable = flags & kSCNetworkReachabilityFlagsReachable;
    [reachability internalCallback:reachable];
}

@implementation ARTOSReachability {
    ARTLog *_logger;
    NSString *_host;
    void (^_callback)(BOOL);
    SCNetworkReachabilityRef _reachabilityRef;
    dispatch_queue_t _queue;
}

- (instancetype)initWithLogger:(ARTLog *)logger queue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _logger = logger;
        _queue = queue;
    }
    return self;
}

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback {
    [self off];
    _host = host;
    _callback = callback;

    _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
        if (SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _queue)) {
            [_logger info:@"Reachability: started listening for host %@", _host];
        }
        else {
            [_logger warn:@"Reachability: failed starting listener for host %@", _host];
        }
    }
}

- (void)off {
    if (_reachabilityRef != NULL) {
        [_logger info:@"Reachability: stopped listening for host %@", _host];
        SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
    _callback = nil;
    _host = nil;
}

- (void)internalCallback:(BOOL)reachable {
    [_logger info:@"Reachability: host %@ is reachable: %@", _host, reachable ? @"true" : @"false"];
    if (_callback) {
        _callback(reachable);
    }
}

- (void)dealloc {
    [self off];
}

@end
