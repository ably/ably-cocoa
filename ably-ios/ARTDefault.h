//
//  ARTDefault.h
//  ably
//
//  Created by vic on 01/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTDefault : NSObject

+ (NSArray*)fallbackHosts;
+ (NSString*)restHost;
+ (NSString*)realtimeHost;
+ (int)TLSPort;
+ (NSTimeInterval)connectTimeout;
+ (NSTimeInterval)disconnectTimeout;
+ (NSTimeInterval)suspendTimeout;

@end
