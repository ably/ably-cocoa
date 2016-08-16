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

extern int (^ARTFallback_getRandomHostIndex)(int count);

@interface ARTFallback : NSObject
{
    
}

/**
 returns a random fallback host, returns null when all hosts have been popped.
 */
-(NSString *) popFallbackHost;

/**
 Init with fallback hosts array.
 */
-(instancetype)initWithFallbackHosts:(NSArray *)fallbackHosts;

@end

ART_ASSUME_NONNULL_END
