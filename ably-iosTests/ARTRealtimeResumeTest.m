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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
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

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
                _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}

//only for use after calling withRealtime
- (void)withRealtime2:(void (^)(ARTRealtime *realtime))cb {
    cb(_realtime2);
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
    [self withRealtime:^(ARTRealtime *realtime) {
        [self withRealtime2:^(ARTRealtime *realtime2) {
            
            __block int disconnects =0;
            ARTRealtimeChannel *channel = [realtime channel:channelName];
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
                if(cState == ARTRealtimeChannelAttached) {
                    [channel2 attach];
                    if(disconnects ==1) {
                        [channel2 publish:message4 cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
                        }];
                    }
                }
            }];
            [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
                //both channels are attached. lets get to work.
                if(cState == ARTRealtimeChannelAttached) {
                    [channel2 publish:message1 cb:^(ARTStatus status) {
                        [channel2 publish:message2 cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
                            disconnects++;
                            [realtime onError:nil];
                        }];
                    }];
                    
                }

            }];
            [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                if(state == ARTRealtimeFailed) {
                    [channel2 publish:message3 cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        [realtime connect];
                    }];
                }
                if(state == ARTRealtimeConnected) {
                    [channel attach];
                }
            }];
            __block bool firstRecieved = false;
            [channel subscribe:^(ARTMessage * message) {
                if([[message content] isEqualToString:message1]) {
                    firstRecieved = true;
                    
                }
                else if([[message content] isEqualToString:message4]) {
                    XCTAssertTrue(firstRecieved);
                    XCTAssertTrue(disconnects>0);
                    [expectation fulfill];
                }
            }];
            
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testSimpleDisconnected
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];
    NSString * channelName = @"resumeChannel";
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    NSString * message3 = @"message3";
    NSString * message4 = @"message4";
    [self withRealtime:^(ARTRealtime *realtime) {
        [self withRealtime2:^(ARTRealtime *realtime2) {
            

            ARTRealtimeChannel *channel = [realtime channel:channelName];
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason)
            {
                if(cState == ARTRealtimeChannelAttached) {
                    [channel2 attach];
                }
            }];
            [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
                //both channels are attached. lets get to work.
                if(cState == ARTRealtimeChannelAttached) {
                    [channel2 publish:message1 cb:^(ARTStatus status) {
                        [channel2 publish:message2 cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
                        }];
                    }];
                    
                }
                
            }];
            [channel subscribe:^(ARTMessage * message) {
                
                NSString * msg = [message content];
                if([msg isEqualToString:message2]) {
                    //disconnect connection1
                    [realtime onError:nil];
                    [channel2 publish:message3 cb:^(ARTStatus status) {
                        [channel2 publish:message4 cb:^(ARTStatus status) {
                            [realtime connect];
                        }];
                    }];
                }
                if([msg isEqualToString:message4]) {
                    [expectation fulfill];
                }
            }];
            
            [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                [channel attach];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



//TODO implement
/*
-(void)testMultipleChannel {
    XCTFail(@"TODO write test");
}

- (void)testResumeMultipleInterval {
    XCTFail(@"TODO write test");
}
 */

@end
