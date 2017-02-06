//
//  ARTRealtimeRecoverTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTRealtime+TestSuite.h"
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTRealtimeChannel.h"
#import "ARTTestUtil.h"
#import "ARTRealtime+Private.h"
#import "ARTEventEmitter.h"

@interface ARTRealtimeRecoverTest : XCTestCase

@end

@implementation ARTRealtimeRecoverTest

- (void)tearDown {
    [super tearDown];
}

- (void)testRecoverDisconnected {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"chanName";
    NSString *c1Message = @"c1 says hi";
    NSString *c2Message = @"c2 says hi";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block NSString *firstConnectionId = nil;
    [realtime.connection once:ARTRealtimeConnectionEventConnected callback:^(ARTConnectionStateChange *stateChange) {
        firstConnectionId = realtime.connection.id;
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        // Sending a message
        [channel publish:nil data:c1Message callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];
    [realtime.connection once:ARTRealtimeConnectionEventDisconnected callback:^(ARTConnectionStateChange *stateChange) {
        options.recover = nil;
        ARTRealtime *realtimeNonRecovered = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *c2 = [realtimeNonRecovered.channels get:channelName];
        // Sending other message to the same channel to check if the recovered connection receives it
        [c2 publish:nil data:c2Message callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [expectation2 fulfill];
        }];
    }];
    [realtime onDisconnected];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    options.recover = realtime.connection.recoveryKey;
    XCTAssertFalse(options.recover == nil);

    __weak XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-3", __FUNCTION__]];
    ARTRealtime *realtimeRecovered = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *c3 = [realtimeRecovered.channels get:channelName];
    [c3 subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects(c2Message, [message data]);
        [expectation3 fulfill];
    }];
    [realtimeRecovered.connection once:ARTRealtimeConnectionEventConnected callback:^(ARTConnectionStateChange *stateChange) {
        XCTAssertEqualObjects(realtimeRecovered.connection.id, firstConnectionId);
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testRecoverFails {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.recover = @"bad_recovery_key:1234";
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState cState = stateChange.current;
        ARTErrorInfo *errorInfo = stateChange.reason;
        // If you connect with an invalid connection Key, then it should connect and get an error saying it could not resume
        if (cState == ARTRealtimeConnected) {
            // 80008 - Unable to recover connection: not found (bad_recovery_key)
            XCTAssertEqual(errorInfo.code, 80008);
            [expectation fulfill];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

@end
