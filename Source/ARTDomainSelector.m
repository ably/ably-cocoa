#import "ARTDomainSelector.h"

NS_ASSUME_NONNULL_BEGIN

// Constants for domain construction
static NSString *const ARTDefaultPrimaryTLD          = @"ably.net";
static NSString *const ARTDefaultNonprodPrimaryTLD   = @"ably-nonprod.net";
static NSString *const ARTDefaultFallbacksTLD        = @"ably-realtime.com";
static NSString *const ARTDefaultNonprodFallbacksTLD = @"ably-realtime-nonprod.com";
static NSString *const ARTDefaultRoutingSubdomain    = @"realtime";
static NSString *const ARTDefaultRoutingPolicy       = @"main";

/**
 The policy that the library will use to determine its REC1 primary domain.
 */
typedef NS_ENUM(NSInteger, ARTPrimaryDomainSelectionPolicy) {
    /// REC1a: The `endpoint` client option has not been specified (used default main.realtime.ably.net, policyId = nil, hostname = nil).
    ARTPrimaryDomainSelectionPolicyDefault,
    
    /// REC1b2: The `endpoint` client option is a hostname (policyId = nil, example hostname = "example.ably.co.uk").
    ARTPrimaryDomainSelectionPolicyHostname,
    
    /// REC1b3: The `endpoint` client option specifies a non-production routing policy (example policyId = "sandbox", hostname = nil).
    ARTPrimaryDomainSelectionPolicyNonProductionRoutingPolicy,
    
    /// REC1b4: The `endpoint` client option is a production routing policy ID (example policyId = "main", hostname = nil).
    ARTPrimaryDomainSelectionPolicyProductionRoutingPolicy,
    
    /// REC1c: Deprecated `environment` option is being used (example policyId = "main", hostname = nil).
    ARTPrimaryDomainSelectionPolicyLegacyEnvironment,
    
    /// REC1d: Deprecated `restHost` or `realtimeHost` option is being used (policyId = nil, example hostname = "example.ably.co.uk").
    ARTPrimaryDomainSelectionPolicyLegacyHost
};

@interface ARTDomainSelector ()

@property (nonatomic) ARTPrimaryDomainSelectionPolicy primaryDomainSelectionPolicy;

/// Prefix used for construction of the primary and fallback domains names (for `ARTPrimaryDomainSelectionPolicyNonProductionRoutingPolicy`, `ARTPrimaryDomainSelectionPolicyProductionRoutingPolicy` and `ARTPrimaryDomainSelectionPolicyLegacyEnvironment` values of ``primaryDomainSelectionPolicy``).
@property (nonatomic, nullable) NSString *policyId;

/// Stores the value of the primary domain if assigned directly (for `ARTPrimaryDomainSelectionPolicyHostname` and `ARTPrimaryDomainSelectionPolicyLegacyHost` values of ``primaryDomainSelectionPolicy``).
@property (nonatomic, nullable) NSString *hostname;
@property (nonatomic, nullable) NSArray<NSString *> *fallbackHostsClientOption;
@property (nonatomic) BOOL fallbackHostsUseDefault;

@end

@implementation ARTDomainSelector

- (instancetype)initWithEndpointClientOption:(nullable NSString *)endpointClientOption
                   fallbackHostsClientOption:(nullable NSArray<NSString *> *)fallbackHostsClientOption
                     environmentClientOption:(nullable NSString *)environmentClientOption
                        restHostClientOption:(nullable NSString *)restHostClientOption
                    realtimeHostClientOption:(nullable NSString *)realtimeHostClientOption
                     fallbackHostsUseDefault:(BOOL)fallbackHostsUseDefault {
    self = [super init];
    if (self) {
        _fallbackHostsClientOption = fallbackHostsClientOption;
        _fallbackHostsUseDefault = fallbackHostsUseDefault;
        [self parsePrimaryDomainSelectionPolicyFromEndpointClientOption:endpointClientOption
                                                            environment:environmentClientOption
                                                               restHost:restHostClientOption
                                                           realtimeHost:realtimeHostClientOption];
    }
    return self;
}

- (instancetype)init {
    return [[self.class alloc] initWithEndpointClientOption:nil
                                  fallbackHostsClientOption:nil
                                    environmentClientOption:nil
                                       restHostClientOption:nil
                                   realtimeHostClientOption:nil
                                    fallbackHostsUseDefault:false];
}

- (void)parsePrimaryDomainSelectionPolicyFromEndpointClientOption:(nullable NSString *)endpointClientOption
                                                      environment:(nullable NSString *)environmentClientOption
                                                         restHost:(nullable NSString *)restHostClientOption
                                                     realtimeHost:(nullable NSString *)realtimeHostClientOption {
    // Check for endpoint first (REC1b)
    if (endpointClientOption != nil && endpointClientOption.length > 0) {
        // REC1b2 - Check if it's a hostname (contains "." or "::" or is "localhost")
        if ([endpointClientOption containsString:@"."] ||
            [endpointClientOption containsString:@"::"] ||
            [endpointClientOption isEqualToString:@"localhost"]) {
            self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyHostname;
            self.hostname = endpointClientOption;
            return;
        }
        
        // REC1b3 - Check if it has "nonprod:" prefix
        NSString *nonprodPrefix = @"nonprod:";
        if ([endpointClientOption hasPrefix:nonprodPrefix]) {
            NSString *policyId = [endpointClientOption substringFromIndex:nonprodPrefix.length];
            self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyNonProductionRoutingPolicy;
            self.policyId = policyId;
            return;
        }
        
        // REC1b4 - Production routing policy
        self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyProductionRoutingPolicy;
        self.policyId = endpointClientOption;
        return;
    }
    
    // Legacy environment handling (REC1c)
    if (environmentClientOption != nil && environmentClientOption.length > 0) {
        self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyLegacyEnvironment;
        self.policyId = environmentClientOption;
        return;
    }
    
    // Legacy host override (REC1d)
    if (restHostClientOption != nil && restHostClientOption.length > 0) {
        self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyLegacyHost;
        self.hostname = restHostClientOption;
        return;
    }
    
    if (realtimeHostClientOption != nil && realtimeHostClientOption.length > 0) {
        self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyLegacyHost;
        self.hostname = realtimeHostClientOption;
        return;
    }
    
    // REC1a - Default
    self.primaryDomainSelectionPolicy = ARTPrimaryDomainSelectionPolicyDefault;
}

- (NSString *)primaryDomain {
    switch (self.primaryDomainSelectionPolicy) {
        // REC1a
        case ARTPrimaryDomainSelectionPolicyDefault:
            return [NSString stringWithFormat:@"%@.%@.%@", ARTDefaultRoutingPolicy, ARTDefaultRoutingSubdomain, ARTDefaultPrimaryTLD];
        
        // REC1b2, REC1d
        case ARTPrimaryDomainSelectionPolicyHostname:
        case ARTPrimaryDomainSelectionPolicyLegacyHost:
            return self.hostname;
        
        // REC1b3
        case ARTPrimaryDomainSelectionPolicyNonProductionRoutingPolicy:
            return [NSString stringWithFormat:@"%@.%@.%@", self.policyId, ARTDefaultRoutingSubdomain, ARTDefaultNonprodPrimaryTLD];
        
        // REC1b4, REC1c
        case ARTPrimaryDomainSelectionPolicyProductionRoutingPolicy:
        case ARTPrimaryDomainSelectionPolicyLegacyEnvironment:
            return [NSString stringWithFormat:@"%@.%@.%@", self.policyId, ARTDefaultRoutingSubdomain, ARTDefaultPrimaryTLD];
    }
}

- (NSArray<NSString *> *)fallbackDomains {
    // REC2a2: First check if explicit fallback hosts are provided
    if (self.fallbackHostsClientOption) {
        return self.fallbackHostsClientOption;
    }
    
    // REC2b: Check deprecated fallbackHostsUseDefault
    if (self.fallbackHostsUseDefault) {
        return [self defaultFallbackDomains];
    }
    
    NSArray<NSString *> *aToE = @[@"a", @"b", @"c", @"d", @"e"];
    
    switch (self.primaryDomainSelectionPolicy) {
        // REC2c1
        case ARTPrimaryDomainSelectionPolicyDefault:
            return [self defaultFallbackDomains];
        
        // REC2c2, REC2c6: legacy hosts handling
        case ARTPrimaryDomainSelectionPolicyHostname:
        case ARTPrimaryDomainSelectionPolicyLegacyHost:
            return @[];
        
        // REC2c3
        case ARTPrimaryDomainSelectionPolicyNonProductionRoutingPolicy: {
            NSMutableArray<NSString *> *domains = [NSMutableArray arrayWithCapacity:aToE.count];
            for (NSString *letter in aToE) {
                NSString *subdomain = [NSString stringWithFormat:@"%@.%@.fallback", self.policyId, letter];
                [domains addObject:[NSString stringWithFormat:@"%@.%@", subdomain, ARTDefaultNonprodFallbacksTLD]];
            }
            return [domains copy];
        }
        
        // REC2c4, REC2c5: legacy environment handling
        case ARTPrimaryDomainSelectionPolicyProductionRoutingPolicy:
        case ARTPrimaryDomainSelectionPolicyLegacyEnvironment: {
            NSMutableArray<NSString *> *domains = [NSMutableArray arrayWithCapacity:aToE.count];
            for (NSString *letter in aToE) {
                NSString *subdomain = [NSString stringWithFormat:@"%@.%@.fallback", self.policyId, letter];
                [domains addObject:[NSString stringWithFormat:@"%@.%@", subdomain, ARTDefaultFallbacksTLD]];
            }
            return [domains copy];
        }
    }
}

- (NSArray<NSString *> *)defaultFallbackDomains {
    // Returns: ["main.a.fallback.ably-realtime.com", "main.b.fallback.ably-realtime.com", ...]
    NSArray<NSString *> *aToE = @[@"a", @"b", @"c", @"d", @"e"];
    NSMutableArray<NSString *> *domains = [NSMutableArray arrayWithCapacity:aToE.count];
    for (NSString *letter in aToE) {
        [domains addObject:[NSString stringWithFormat:@"%@.%@.fallback.%@", ARTDefaultRoutingPolicy, letter, ARTDefaultFallbacksTLD]];
    }
    return [domains copy];
}

@end

NS_ASSUME_NONNULL_END
