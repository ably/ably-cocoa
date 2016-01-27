//
//  ARTTestUtil.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "ARTClientOptions.h"
#import "ARTRest.h"
#import "ARTRealtime.h"

@class ARTChannel;
@class XCTestExpectation;
@class ARTRealtimeChannel;
@class ARTCipherPayloadEncoder;

void waitForWithTimeout(NSUInteger *counter, NSArray *list, NSTimeInterval timeout);

@interface ARTTestUtil : NSObject

typedef NS_ENUM(NSUInteger, TestAlteration) {
    TestAlterationNone,
    TestAlterationBadKeyId,
    TestAlterationBadKeyValue,
    TestAlterationBadWsHost,
    TestAlterationRestrictCapability
};

+ (ARTCipherPayloadEncoder *)getTestCipherEncoder;

// FIXME: why is `setupApp` using a callback? hard reading... could be a blocking method (only once per test)
+ (void)setupApp:(ARTClientOptions *)options cb:(void(^)(ARTClientOptions *options))cb;
+ (void)setupApp:(ARTClientOptions *)options withAlteration:(TestAlteration) alt cb:(void (^)(ARTClientOptions *))cb;
+ (void)setupApp:(ARTClientOptions *)options withDebug:(BOOL)debug cb:(void (^)(ARTClientOptions *))cb;
+ (void)setupApp:(ARTClientOptions *)options withDebug:(BOOL)debug withAlteration:(TestAlteration) alt cb:(void (^)(ARTClientOptions *))cb;
+ (float)timeout;

+ (ARTClientOptions *)clientOptions;

typedef void (^ARTRestConstructorCb)(ARTRest *rest);
typedef void (^ARTRealtimeConstructorCb)(ARTRealtime *realtime);
typedef void (^ARTRealtimeTestCallback)(ARTRealtime *realtime, ARTRealtimeConnectionState state, XCTestExpectation *expectation);

+ (void)testRest:(ARTRestConstructorCb)cb;

+ (void)testRealtime:(ARTClientOptions *)options callback:(ARTRealtimeConstructorCb)cb;

// FIXME: try to unify testRealtime, testRealtimeV2 and others that are private
+ (void)testRealtime:(ARTRealtimeConstructorCb)cb;

/**
 New RealtimeClient instance

 Creates implicitly a XCTestExpectation.
 The callback is called only if the RealtimeClient gets connected.
 */
+ (void)testRealtimeV2:(XCTestCase *)testCase withDebug:(BOOL)debug callback:(ARTRealtimeTestCallback)callback;

+ (void)repeat:(int)count i:(int)i delay:(NSTimeInterval)delay block:(void (^)(int))block;
+ (void)repeat:(int)count delay:(NSTimeInterval)delay block:(void (^)(int))block ;

+ (long long)nowMilli;
+ (float)smallSleep;
+ (float)bigSleep;

+ (void)publishRestMessages:(NSString *) prefix count:(int) count channel:(ARTChannel *)channel completion:(void (^)())completion;
+ (void)publishRealtimeMessages:(NSString *)prefix count:(int)count channel:(ARTRealtimeChannel *)channel completion:(void (^)())completion;
+ (void)publishEnterMessages:(NSString *)clientIdPrefix count:(int)count channel:(ARTRealtimeChannel *)channel completion:(void (^)())completion;

+ (NSString *)getCrypto128Json;
+ (NSString *)getTestAppSetupJson;
+ (NSString *)getCrypto256Json;
+ (NSString *)getErrorsJson;

+ (ARTProtocolMessage *)newErrorProtocolMessage;

@end
