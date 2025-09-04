#import "Ably.h"
#import "ARTDefault+Private.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTClientInformation+Private.h"

NSString *const ARTDefaultPrimaryTLD           = @"ably.net";
NSString *const ARTDefaultNonprodPrimaryTLD    = @"ably-nonprod.net";
NSString *const ARTDefaultFallbacksTLD         = @"ably-realtime.com";
NSString *const ARTDefaultNonprodFallbacksTLD  = @"ably-realtime-nonprod.com";
NSString *const ARTDefaultRoutingSubdomain     = @"realtime";
NSString *const ARTDefaultRoutingPolicy        = @"main";
NSString *const ARTDefaultFallbackSubdomains   = @"a,b,c,d,e";
NSString *const ARTDefaultConnectivityCheckUrl = @"internet-up.ably-realtime.com/is-the-internet-up.txt";

NSString *const ARTDefaultAPIVersion = @"2"; // CSV2
NSString *const ARTDefaultProductionEnvironment = @"production";

NSTimeInterval ARTConnectionStateTtl = 60.0;
NSInteger ARTMaxProductionMessageSize = 65536;
NSInteger ARTMaxSandboxMessageSize = 16384;

@implementation ARTDefault

+ (NSString *)apiVersion {
    return ARTDefaultAPIVersion;
}

+ (NSString *)libraryVersion {
    return ARTClientInformationLibraryVersion;
}

+ (NSString *)primaryDomain {
    // main.realtime.ably.net
    return [NSString stringWithFormat:@"%@.%@.%@", ARTDefaultRoutingPolicy, ARTDefaultRoutingSubdomain, ARTDefaultPrimaryTLD];
}

+ (NSString *)primaryDomainForRoutingPolicy:(NSString *)routingPolicy {
    // [policy].realtime.ably.net
    return [NSString stringWithFormat:@"%@.%@.%@", routingPolicy, ARTDefaultRoutingSubdomain, ARTDefaultPrimaryTLD];
}

+ (NSString *)nonprodPrimaryDomainForRoutingPolicy:(NSString *)routingPolicy {
    // [policy].realtime.ably-nonprod.net
    return [NSString stringWithFormat:@"%@.%@.%@", routingPolicy, ARTDefaultRoutingSubdomain, ARTDefaultNonprodPrimaryTLD];
}

+ (NSArray<NSString *> *)fallbackSubdomains {
    // ["a", "b", "c", "d", "e"]
    return [ARTDefaultFallbackSubdomains componentsSeparatedByString:@","];
}

+ (NSArray<NSString *> *)fallbackSubdomainsForRoutingPolicy:(NSString *)routingPolicy {
    // [policy].[a-e].fallback
    return [self.fallbackSubdomains artMap:^NSString *(NSString *fallback) {
        return [NSString stringWithFormat:@"%@.%@.fallback", routingPolicy, fallback];
    }];
}

+ (NSArray<NSString *> *)fallbackDomains {
    // [a-e].ably-realtime.com
    return [self.fallbackSubdomains artMap:^NSString * (NSString *fallback) {
        return [NSString stringWithFormat:@"%@.%@", fallback, ARTDefaultFallbacksTLD];
    }];
}

+ (NSArray<NSString *> *)fallbackNonprodDomainsForRoutingPolicy:(NSString *)routingPolicy {
    // [policy].[a-e].fallback.ably-realtime-nonprod.com
    return [[self fallbackSubdomainsForRoutingPolicy:routingPolicy] artMap:^NSString * (NSString *fallback) {
        return [NSString stringWithFormat:@"%@.%@", fallback, ARTDefaultNonprodFallbacksTLD];
    }];
}

+ (NSArray<NSString *> *)fallbackDomainsForRoutingPolicy:(NSString *)routingPolicy {
    // [policy].[a-e].fallback.ably-realtime.com
    return [[self fallbackSubdomainsForRoutingPolicy:routingPolicy] artMap:^NSString * (NSString *fallback) {
        return [NSString stringWithFormat:@"%@.%@", fallback, ARTDefaultFallbacksTLD];
    }];
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
#if DEBUG
    return ARTMaxSandboxMessageSize;
#else
    return ARTMaxProductionMessageSize;
#endif
}

+ (NSInteger)maxSandboxMessageSize {
    return ARTMaxSandboxMessageSize;
}

+ (NSInteger)maxProductionMessageSize {
    return ARTMaxProductionMessageSize;
}

+ (void)setConnectionStateTtl:(NSTimeInterval)value {
    @synchronized (self) {
        ARTConnectionStateTtl = value;
    }
}

+ (void)setMaxMessageSize:(NSInteger)value {
    @synchronized (self) {
#if DEBUG
        ARTMaxSandboxMessageSize = value;
#else
        ARTMaxProductionMessageSize = value;
#endif
    }
}

+ (void)setMaxProductionMessageSize:(NSInteger)value {
    @synchronized (self) {
        ARTMaxProductionMessageSize = value;
    }
}

+ (void)setMaxSandboxMessageSize:(NSInteger)value {
    @synchronized (self) {
        ARTMaxSandboxMessageSize = value;
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
