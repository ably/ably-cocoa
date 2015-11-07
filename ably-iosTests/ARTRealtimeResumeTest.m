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

@interface ARTRealtimeResumeTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end

@implementation ARTRealtimeResumeTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _realtime = nil;
    _realtime2 = nil;
    [super tearDown];
}


/**
  create 2 connections, each connected to the same channel.
 disonnect and reconnect one of the connections, then use that channel
 to send and recieve message. verify all messages sent and recieved ok.
 */

-(void) testSimple
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimple"];
    NSString * channelName = @"resumeChannel";
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    NSString * message3 = @"message3";
    NSString * message4 = @"message4";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];

        __block int disconnects =0;
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel2 attach];
                if(disconnects ==1) {
                    [channel2 publish:message4 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStateOk, status.state);
                    }];
                }
            }
        }];
        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            //both channels are attached. lets get to work.
            if(cState == ARTRealtimeChannelAttached) {
                [channel2 publish:message1 cb:^(ARTStatus *status) {
                    [channel2 publish:message2 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStateOk, status.state);
                        disconnects++;
                        [_realtime onError:nil withErrorInfo:nil];
                    }];
                }];
            }
        }];
        [_realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if(state == ARTRealtimeFailed) {
                [channel2 publish:message3 cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStateOk, status.state);
                    [_realtime connect];
                }];
            }
            if(state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testSimpleDisconnected {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];
    NSString * channelName = @"resumeChannel";
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    NSString * message3 = @"message3";
    NSString * message4 = @"message4";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel2 attach];
            }
        }];
        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            //both channels are attached. lets get to work.
            if(cState == ARTRealtimeChannelAttached) {
                [channel2 publish:message1 cb:^(ARTStatus *status) {
                    [channel2 publish:message2 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStateOk, status.state);
                    }];
                }];
            }
        }];
        [channel subscribe:^(ARTMessage * message, ARTErrorInfo *errorInfo) {
            NSString * msg = [message content];
            if([msg isEqualToString:message2]) {
                //disconnect connection1
                [_realtime onError:nil withErrorInfo:nil];
                [channel2 publish:message3 cb:^(ARTStatus *status) {
                    [channel2 publish:message4 cb:^(ARTStatus *status) {
                        [_realtime connect];
                    }];
                }];
            }
            if([msg isEqualToString:message4]) {
                [expectation fulfill];
            }
        }];
        
        [_realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            [channel attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
