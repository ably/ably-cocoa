//
//  ARTFallback.m
//  ably
//
//  Created by vic on 19/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTFallback+Private.h"

#import "ARTDefault.h"
#import "ARTStatus.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"

void (^ARTFallback_shuffleArray)(NSMutableArray *) = ^void(NSMutableArray *a) {
    for (NSUInteger i = a.count; i > 1; i--) {
        [a exchangeObjectAtIndex:i - 1 withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    }
};

@interface ARTFallback ()

@end

@implementation ARTFallback

- (instancetype)initWithFallbackHosts:(nullable NSArray<NSString *> *)fallbackHosts {
    self = [super init];
    if (self) {
        if (fallbackHosts != nil && fallbackHosts.count == 0) {
            return nil;
        }
        self.hosts = [[NSMutableArray alloc] initWithArray: fallbackHosts ? fallbackHosts : [ARTDefault fallbackHosts]];
        ARTFallback_shuffleArray(self.hosts);
    }
    return self;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    if (options.fallbackHostsUseDefault) {
        return [self initWithFallbackHosts:nil]; //default
    }
    return [self initWithFallbackHosts:options.fallbackHosts];
}

- (instancetype)init {
    return [self initWithFallbackHosts:nil];
}

- (NSString *)popFallbackHost {
    if ([self.hosts count] ==0) {
        return nil;
    }
    NSString *host = [self.hosts lastObject];
    [self.hosts removeLastObject];
    return host;
}

+ (BOOL)restShouldFallback:(NSURL *)url withOptions:(ARTClientOptions *)options {
    // Default REST
    if ([url.host isEqualToString:[ARTDefault restHost]]) {
        return YES;
    }
    // Custom host / environment
    else if (options.fallbackHostsUseDefault) {
        return YES;
    }
    return NO;
}

+ (BOOL)realtimeShouldFallback:(NSURL *)url withOptions:(ARTClientOptions *)options {
    // Default Realtime
    if ([url.host isEqualToString:[ARTDefault realtimeHost]]) {
        return YES;
    }
    // Custom host / environment
    else if (options.fallbackHostsUseDefault) {
        return YES;
    }
    return NO;
}

@end
