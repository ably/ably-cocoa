#import "Ably.h"
#import "ARTDefault+Private.h"
#import "ARTClientInformation+Private.h"
#import "ARTDomainSelector.h"

NSString *const ARTDefaultAPIVersion = @"4"; // CSV2

NSTimeInterval ARTConnectionStateTtl = 60.0;
NSInteger ARTMaxMessageSize = 65536; // 16384 in sandbox

NSString *const ARTDefaultConnectivityCheckUrl = @"internet-up.ably-realtime.com/is-the-internet-up.txt";

@implementation ARTDefault

+ (NSString *)apiVersion {
    return ARTDefaultAPIVersion;
}

+ (NSString *)libraryVersion {
    return ARTClientInformation_libraryVersion;
}

+ (NSArray<NSString *> *)fallbackHostsWithEnvironment:(NSString *_Nullable)environment {
    return [[[ARTDomainSelector alloc] initWithEndpointClientOption:nil
                                          fallbackHostsClientOption:nil
                                            environmentClientOption:environment
                                               restHostClientOption:nil
                                           realtimeHostClientOption:nil
                                            fallbackHostsUseDefault:false] fallbackDomains];
}

+ (NSArray<NSString *> *)fallbackHosts {
    return [self fallbackHostsWithEnvironment:nil];
}

+ (NSString *)restHost {
    return [[ARTDomainSelector alloc] init].primaryDomain;
}

+ (NSString *)realtimeHost {
    return [[ARTDomainSelector alloc] init].primaryDomain;
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
    return ARTConnectionStateTtl;
}

+ (NSTimeInterval)realtimeRequestTimeout {
    return 10.0;
}

+ (NSInteger)maxMessageSize {
    return ARTMaxMessageSize;
}

+ (void)setConnectionStateTtl:(NSTimeInterval)value {
    @synchronized (self) {
        ARTConnectionStateTtl = value;
    }
}

+ (void)setMaxMessageSize:(NSInteger)value {
    @synchronized (self) {
        ARTMaxMessageSize = value;
    }
}

+ (NSString *)libraryAgent {
    return [ARTClientInformation libraryAgentIdentifier];
}

+ (NSString *)platformAgent {
    return [ARTClientInformation platformAgentIdentifier];
}

+ (NSString *)connectivityCheckUrl {
    return [NSString stringWithFormat:@"https://%@", ARTDefaultConnectivityCheckUrl];
}

@end
