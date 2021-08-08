//
//  ARTFallbackHosts.m
//  Ably
//
//  Created by Ricardo Pereira on 29/04/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import "ARTFallbackHosts.h"

#import "ARTDefault+Private.h"
#import "ARTClientOptions+Private.h"

@implementation ARTFallbackHosts

+ (nullable NSArray<NSString *> *)hostsFromOptions:(ARTClientOptions *)options {
    if (options.fallbackHosts) {
        return options.fallbackHosts;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (options.fallbackHostsUseDefault) {
        return [ARTDefault fallbackHosts];
    }
#pragma clang diagnostic pop

    if (options.hasEnvironmentDifferentThanProduction) {
        return [ARTDefault fallbackHostsWithEnvironment:options.environment];
    }
    if (options.hasCustomRestHost || options.hasCustomRealtimeHost || options.hasCustomPort || options.hasCustomTlsPort) {
        return nil;
    }
    return [ARTDefault fallbackHosts];
}

@end
