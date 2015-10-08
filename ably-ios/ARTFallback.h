//
//  ARTFallback.h
//  ably
//
//  Created by vic on 19/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTHttpResponse;
@class ARTClientOptions;

@interface ARTFallback : NSObject
{
    
}

/**
 returns a random fallback host, returns null when all hosts have been popped.
 */
-(NSString *) popFallbackHost;
+(bool) shouldTryFallback:(ARTHttpResponse *) response  options:(ARTClientOptions *) options;

@end
