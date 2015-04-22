//
//  ARTTestUtil.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTOptions.h"
@class ARTRestChannel;
@class XCTestExpectation;
@class ARTRealtimeChannel;

@interface ARTTestUtil : NSObject





typedef NS_ENUM(NSUInteger, TestAlteration) {
    TestAlterationNone,
    TestAlterationBadKeyId,
    TestAlterationBadKeyValue,
    TestAlterationBadWsHost
};


+ (void)setupApp:(ARTOptions *)options cb:(void(^)(ARTOptions *options))cb;
+(void) setupApp:(ARTOptions *)options withAlteration:(TestAlteration) alt cb:(void (^)(ARTOptions *))cb;
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
+(float) smallSleep;
+(float) bigSleep;

+(void) publishRestMessages:(NSString *) prefix count:(int) count channel:(ARTRestChannel *) channel expectation:(XCTestExpectation *) expectation;

+(void) publishRealtimeMessages:(NSString *) prefix count:(int) count channel:(ARTRealtimeChannel *) channel expectation:(XCTestExpectation *) expectation;

+(NSString *) getCrypto128Json;
+(NSString *) getTestAppSetupJson;
+(NSString *) getCrypto256Json;
+(NSString *) getErrorsJson;
@end



