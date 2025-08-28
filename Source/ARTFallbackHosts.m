#import "ARTFallbackHosts.h"

#import "ARTDefault+Private.h"
#import "ARTClientOptions+Private.h"
#import "ARTNSString+ARTUtil.h"

@implementation ARTFallbackHosts

+ (nullable NSArray<NSString *> *)hostsFromOptions:(ARTClientOptions *)options {
    // First check if explicit fallback hosts are provided
    if (options.fallbackHosts) {
        return options.fallbackHosts;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (options.fallbackHostsUseDefault) {
        return [ARTDefault fallbackHosts];
    }
#pragma clang diagnostic pop

    // If using endpoint, generate fallbacks based on the endpoint
    if (options.endpoint && [options.endpoint isNotEmptyString]) {
        return [options endpointFallbackHosts:options.endpoint];
    }

    // Legacy environment handling
    if (options.hasEnvironmentDifferentThanProduction) {
        return [ARTDefault fallbackHostsWithEnvironment:options.environment];
    }
    
    // If custom hosts or ports are set, don't use fallbacks
    if (options.hasCustomRestHost || options.hasCustomRealtimeHost || options.hasCustomPort || options.hasCustomTlsPort) {
        return nil;
    }
    
    return [ARTDefault fallbackHosts];
}

@end
