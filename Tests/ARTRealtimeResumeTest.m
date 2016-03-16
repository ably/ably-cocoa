//
//  ARTRealtimeResumeTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTRealtimeChannel.h"
#import "ARTEventEmitter.h"
#import "ARTTestUtil.h"
#import "ARTRealtime+Private.h"

@interface ARTRealtimeResumeTest : XCTestCase {
    ARTRealtime *_realtime;
    ARTRealtime *_realtime2;
}

@end

@implementation ARTRealtimeResumeTest

- (void)tearDown {
    if (_realtime) {
        [ARTTestUtil removeAllChannels:_realtime];
        [_realtime resetEventEmitter];
        [_realtime close];
    }
    _realtime = nil;
    if (_realtime2) {
        [ARTTestUtil removeAllChannels:_realtime2];
        [_realtime2 resetEventEmitter];
        [_realtime2 close];
    }
    _realtime2 = nil;
    [super tearDown];
}

- (void)testSimpleDisconnected {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];
    NSString *channelName = @"resumeChannel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";
    NSString *message3 = @"message3";
    NSString *message4 = @"message4";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
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
                [_realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                [channel2 publish:nil data:message3 callback:^(ARTErrorInfo *errorInfo) {
                    [channel2 publish:nil data:message4 callback:^(ARTErrorInfo *errorInfo) {
                        [_realtime connect];
                    }];
                }];
            }
            if([msg isEqualToString:message4]) {
                [expectation fulfill];
            }
        }];
        
        [_realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            [channel attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
