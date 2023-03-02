#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "ARTOSReachability.h"

/// Global callback for network state changes
static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    void (^callbackBlock)(SCNetworkReachabilityFlags) = (__bridge id)info;
    callbackBlock(flags);
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

    __weak ARTOSReachability *weakSelf = self;
    void (^callbackBlock)(SCNetworkReachabilityFlags) = ^(SCNetworkReachabilityFlags flags) {
        ARTOSReachability *strongSelf = weakSelf;
        if (strongSelf) {
            BOOL reachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
            [strongSelf->_logger info:@"Reachability: host %@ is reachable: %@", strongSelf->_host, reachable ? @"true" : @"false"];
            dispatch_async(strongSelf->_queue, ^{
                if (strongSelf->_callback) {
                    strongSelf->_callback(reachable);
                }
            });
        }
    };
    
    _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    
    SCNetworkReachabilityContext context = { .version = 0, .info = (void *)CFBridgingRetain(callbackBlock), .release = CFRelease };
    
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
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
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
    _callback = nil;
    _host = nil;
}

- (void)internalCallback:(BOOL)reachable {
    [_logger info:@"Reachability: host %@ is reachable: %@", _host, reachable ? @"true" : @"false"];
    dispatch_async(_queue, ^{
        if (self->_callback) self->_callback(reachable);
    });
}

- (void)dealloc {
    [self off];
}

@end
