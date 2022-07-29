#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "ARTOSReachability.h"

NSNotificationName const kARTOSReachabilityNetworkIsReachableNotification = @"ARTOSReachabilityNetworkIsReachableNotification";
NSNotificationName const kARTOSReachabilityNetworkIsDownNotification = @"ARTOSReachabilityNetworkIsDownNotification";

/// Global callback for network state changes
static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *_Nullable info) {
    // Post a notification to notify the instance that the network reachability changed.
    BOOL reachable = flags & kSCNetworkReachabilityFlagsReachable;
    if (reachable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:kARTOSReachabilityNetworkIsReachableNotification object:nil];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:kARTOSReachabilityNetworkIsDownNotification object:nil];
        });
    }
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

    if(_queue == nil) {
        dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        _queue = dispatch_queue_create("com.ably.reachability-monitor", attrs);
    }

    _reachabilityRef = CFAutorelease(SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [host UTF8String]));

    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkIsReachable) name:kARTOSReachabilityNetworkIsReachableNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkIsDown) name:kARTOSReachabilityNetworkIsDownNotification object:nil];

    if(SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _queue)){
        if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
                [_logger info:@"Reachability: started listening for host %@", _host];
            }
            else {
                [_logger warn:@"Reachability: failed starting listener for host %@", _host];
            }
        }
        else {
            [_logger warn:@"Reachability: failed setting callback for %@", _host];
            [self removeAllObservers];
        }
    }
    else {
        [_logger info:@"Reachability: failed setting dispatch queue for  %@", _host];
        [self removeAllObservers];
    }
}

- (void)off {
    if (_reachabilityRef != NULL) {
        [self removeAllObservers];

        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
        SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        [_logger info:@"Reachability: stopped listening for host %@", _host];
    }
    _callback = nil;
    _host = nil;
}

- (void)removeAllObservers {
    [NSNotificationCenter.defaultCenter removeObserver:self name:kARTOSReachabilityNetworkIsReachableNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kARTOSReachabilityNetworkIsDownNotification object:nil];
}

- (void)networkIsReachable {
    [self internalCallback:true];
}

- (void)networkIsDown {
    [self internalCallback:false];
}

- (void)internalCallback:(BOOL)reachable {
    [_logger info:@"Reachability: host %@ is reachable: %@", _host, reachable ? @"true" : @"false"];
    dispatch_async(_queue, ^{
        if (self->_callback)
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_callback(reachable);
        });

    });
}

- (void)dealloc {
    [self off];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
}

@end
