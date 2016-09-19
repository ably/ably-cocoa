//
//  ARTRealtimeResumeTest.m
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
#import "ARTEventEmitter.h"
#import "ARTTestUtil.h"
#import "ARTRealtime+Private.h"

@interface ARTRealtimeResumeTest : XCTestCase

@end

@implementation ARTRealtimeResumeTest

- (void)tearDown {
    [super tearDown];
}

- (void)testSimpleDisconnected {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    
    NSString *channelName = @"resumeChannel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";
    NSString *message3 = @"message3";
    NSString *message4 = @"message4";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];

    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
    [channel on:^(ARTErrorInfo *errorInfo) {
        if(channel.state == ARTRealtimeChannelAttached) {
            [channel2 attach];
        }
    }];
    [channel2 on:^(ARTErrorInfo *errorInfo) {
        //both channels are attached. lets get to work.
        if(channel2.state == ARTRealtimeChannelAttached) {
            [channel2 publish:nil data:message1 callback:^(ARTErrorInfo *errorInfo) {
                [channel2 publish:nil data:message2 callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }];
        }
    }];
    [channel subscribe:^(ARTMessage *message) {
        NSString *msg = [message data];
        if([msg isEqualToString:message2]) {
            //disconnect connection1
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            [channel2 publish:nil data:message3 callback:^(ARTErrorInfo *errorInfo) {
                [channel2 publish:nil data:message4 callback:^(ARTErrorInfo *errorInfo) {
                    [realtime connect];
                }];
            }];
        }
        if([msg isEqualToString:message4]) {
            [expectation fulfill];
        }
    }];
    
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

@end
