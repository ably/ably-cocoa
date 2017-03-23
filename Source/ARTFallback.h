//
//  ARTFallback.h
//  ably
//
//  Created by vic on 19/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

@class ARTHttpResponse;
@class ARTClientOptions;

@interface ARTFallback : NSObject

/**
 Init with options.
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 Init with fallback hosts array.
 */
- (instancetype)initWithFallbackHosts:(art_nullable __GENERIC(NSArray, NSString *) *)fallbackHosts;

/**
 returns a random fallback host, returns null when all hosts have been popped.
 */
- (nullable NSString *)popFallbackHost;

@end

ART_ASSUME_NONNULL_END
