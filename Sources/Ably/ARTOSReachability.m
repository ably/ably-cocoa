#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "ARTOSReachability.h"
#import "ARTInternalLog.h"

typedef const void * __nonnull (* __nullable ARTNetworkReachabilityContextRetain)(const void * _Nullable info);

/// Global callback for network state changes
static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    void (^callbackBlock)(SCNetworkReachabilityFlags) = (__bridge id)info;
    callbackBlock(flags);
}

@implementation ARTOSReachability {
    ARTInternalLog *_logger;
    NSString *_host;
    SCNetworkReachabilityRef _reachabilityRef;
    dispatch_queue_t _queue;
}

- (instancetype)initWithLogger:(ARTInternalLog *)logger queue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _logger = logger;
        _queue = queue;
    }
    return self;
}

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback {
    [self off];
    _host = host;

    // This strategy is taken from Mike Ash's book "The Complete Friday Q&A: Volume III".
    // Article: https://www.mikeash.com/pyblog/friday-qa-2013-06-14-reachability.html
    
    __weak ARTOSReachability *weakSelf = self;
    void (^callbackBlock)(SCNetworkReachabilityFlags) = ^(SCNetworkReachabilityFlags flags) {
        ARTOSReachability *strongSelf = weakSelf;
        if (strongSelf) {
            BOOL reachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
            ARTLogInfo(strongSelf->_logger, @"Reachability: host %@ is reachable: %@", strongSelf->_host, reachable ? @"true" : @"false");
            dispatch_async(strongSelf->_queue, ^{
                if (callback) {
                    callback(reachable);
                }
            });
        }
    };
    
    _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    
    SCNetworkReachabilityContext context = {
        .version = 0,
        .info = (__bridge void *)(callbackBlock),
        .retain = (ARTNetworkReachabilityContextRetain)CFBridgingRetain,
        .release = CFRelease
    };
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            ARTLogInfo(_logger, @"Reachability: started listening for host %@", _host);
        }
        else {
            ARTLogWarn(_logger, @"Reachability: failed starting listener for host %@", _host);
        }
    }
}

- (void)off {
    if (_reachabilityRef != NULL) {
        ARTLogInfo(_logger, @"Reachability: stopped listening for host %@", _host);
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
    _host = nil;
}

- (void)dealloc {
    [self off];
}

@end
