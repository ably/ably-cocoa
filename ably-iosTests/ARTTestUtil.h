//
//  ARTTestUtil.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTOptions.h"

@interface ARTTestUtil : NSObject

+ (void)setupApp:(ARTOptions *)options cb:(void(^)(ARTOptions *options))cb;
+ (NSString *) restHost;
+ (NSString *) realtimeHost;
+ (float) timeout;


+(ARTOptions *) jsonRealtimeOptions;
+(ARTOptions *) jsonRestOptions;
+(ARTOptions *) binaryRestOptions;
+(ARTOptions *) binaryRealtimeOptions;


+(void)repeat:(int)count i:(int)i delay:(NSTimeInterval)delay block:(void (^)(int))block;
+(void)repeat:(int)count delay:(NSTimeInterval)delay block:(void (^)(int))block ;

+(long long) nowMilli;
@end



