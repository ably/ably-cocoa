//
//  ARTTestUtil.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTClientOptions.h"
#import "ARTRest.h"
#import "ARTRealtime.h"

@class ARTChannel;
@class XCTestExpectation;
@class ARTRealtimeChannel;
@class ARTCipherPayloadEncoder;

@interface ARTTestUtil : NSObject

typedef NS_ENUM(NSUInteger, TestAlteration) {
    TestAlterationNone,
    TestAlterationBadKeyId,
    TestAlterationBadKeyValue,
    TestAlterationBadWsHost,
    TestAlterationRestrictCapability
};

+ (ARTCipherPayloadEncoder *)getTestCipherEncoder;

+ (void)setupApp:(ARTClientOptions *)options cb:(void(^)(ARTClientOptions *options))cb;
+ (void)setupApp:(ARTClientOptions *)options withAlteration:(TestAlteration) alt cb:(void (^)(ARTClientOptions *))cb;
+ (float)timeout;

+ (ARTClientOptions *)clientOptions;

typedef void (^ARTRestConstructorCb)(ARTRest *rest);
typedef void (^ARTRealtimeConstructorCb)(ARTRealtime *realtime);

+ (void)testRest:(ARTRestConstructorCb)cb;
+ (void)testRealtime:(ARTRealtimeConstructorCb)cb;

+ (void)repeat:(int)count i:(int)i delay:(NSTimeInterval)delay block:(void (^)(int))block;
+ (void)repeat:(int)count delay:(NSTimeInterval)delay block:(void (^)(int))block ;

+ (long long)nowMilli;
+ (float)smallSleep;
+ (float)bigSleep;

+ (void)publishRestMessages:(NSString *) prefix count:(int) count channel:(ARTChannel *)channel expectation:(XCTestExpectation *)expectation;

+ (void)publishRealtimeMessages:(NSString *)prefix count:(int)count channel:(ARTRealtimeChannel *)channel expectation:(XCTestExpectation *)expectation;
+ (void)publishEnterMessages:(NSString *)clientIdPrefix count:(int)count channel:(ARTRealtimeChannel *)channel expectation:(XCTestExpectation *)expectation;

+ (NSString *)getCrypto128Json;
+ (NSString *)getTestAppSetupJson;
+ (NSString *)getCrypto256Json;
+ (NSString *)getErrorsJson;

@end
