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

ART_ASSUME_NONNULL_BEGIN

@class ARTChannel;
@class XCTestExpectation;
@class ARTRealtimeChannel;
@class ARTCipherDataEncoder;

@interface ARTTestUtil : NSObject

typedef NS_ENUM(NSUInteger, TestAlteration) {
    TestAlterationNone,
    TestAlterationBadKeyId,
    TestAlterationBadKeyValue,
    TestAlterationBadWsHost,
    TestAlterationRestrictCapability
};

+ (ARTCipherDataEncoder *)getTestCipherEncoder;

// FIXME: why is `setupApp` using a callback? hard reading... could be a blocking method (only once per test)
+ (void)setupApp:(ARTClientOptions *)options callback:(void(^)(ARTClientOptions *options))cb;
+ (void)setupApp:(ARTClientOptions *)options withAlteration:(TestAlteration) alt callback:(void (^)(ARTClientOptions *))cb;
+ (void)setupApp:(ARTClientOptions *)options withDebug:(BOOL)debug callback:(void (^)(ARTClientOptions *))cb;
+ (void)setupApp:(ARTClientOptions *)options withDebug:(BOOL)debug withAlteration:(TestAlteration) alt callback:(void (^)(ARTClientOptions *))cb;
+ (float)timeout;

+ (ARTClientOptions *)clientOptions;

+ (ARTClientOptions *)newSandboxApp:(XCTestCase *)testCase withDescription:(const char *)description;

typedef void (^ARTRestConstructorCb)(ARTRest *rest);
typedef void (^ARTRealtimeConstructorCb)(ARTRealtime *realtime);

+ (void)testRest:(ARTRestConstructorCb)cb;
+ (void)testRealtime:(ARTClientOptions *)options callback:(ARTRealtimeConstructorCb)cb;
+ (void)testRealtime:(ARTRealtimeConstructorCb)cb;

+ (void)repeat:(int)count i:(int)i delay:(NSTimeInterval)delay block:(void (^)(int))block;
+ (void)repeat:(int)count delay:(NSTimeInterval)delay block:(void (^)(int))block ;

+ (long long)nowMilli;
+ (float)smallSleep;
+ (float)bigSleep;

+ (void)publishRestMessages:(NSString *) prefix count:(int) count channel:(ARTChannel *)channel completion:(void (^)())completion;
+ (void)publishRealtimeMessages:(NSString *)prefix count:(int)count channel:(ARTRealtimeChannel *)channel completion:(void (^)())completion;
+ (void)publishEnterMessages:(NSString *)clientIdPrefix count:(int)count channel:(ARTRealtimeChannel *)channel completion:(void (^)())completion;

+ (NSString *)getTestAppSetupJson;
+ (NSString *)getErrorsJson;

+ (ARTProtocolMessage *)newErrorProtocolMessage;

+ (void)removeAllChannels:(ARTRealtime *)realtime;

+ (void)convertException:(void (^)())block error:(NSError *__art_nullable*__art_nullable)error;

+ (void)waitForWithTimeout:(NSUInteger *_Nonnull)counter list:(NSArray *)list timeout:(NSTimeInterval)timeout;
+ (void)delay:(NSTimeInterval)timeout block:(dispatch_block_t)block;

+ (void(^)())splitFulfillFrom:(XCTestCase *)testCase expectation:(XCTestExpectation *)expectation in:(NSInteger)howMany;

@end

ART_ASSUME_NONNULL_END
