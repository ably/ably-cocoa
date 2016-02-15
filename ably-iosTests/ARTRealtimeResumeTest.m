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

/**
 testSimple:
  - Client A & Client B connect, attach to channel Y
  - Client A is forcibly disconnected and does not (yet) reconnect and attempt resume
  - Client B then publishes some messages on channel Y, and waits until the messages are received on channel Y
  - Client A reconnects and resumes the connection. As connection resume should be working, it then receives the messages on channel Y whilst the client was disconnected, and channel Y of course remains attached
 */
- (void)testSimple {
    NSString *channelName = @"resumeChannel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";

    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimple"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];

        ARTRealtimeChannel *channelA = [_realtime.channels get:channelName];
        ARTRealtimeChannel *channelB = [_realtime2.channels get:channelName];

        [channelA on:^(ARTErrorInfo *errorInfo) {
            if (channelA.state == ARTRealtimeChannelAttached) {
                // 2. Attach channel of Client B
                [channelB attach];
            }
        }];

        [channelB on:^(ARTErrorInfo *errorInfo) {
            if (channelB.state == ARTRealtimeChannelAttached) {
                // 3. Client B sends message and if OK then force A to disconnect
                [channelB publish:nil data:message1 cb:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    // Forcibly disconnect
                    [_realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                }];
            }
        }];

        [_realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeFailed) {
                // 4. Client A is disconnected and B sends message
                [channelB publish:nil data:message2 cb:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [channelA subscribe:^(ARTMessage *message) {
                        // 6. Check if Client A receives the last message
                        if ([message.data isEqual:message2]) {
                            [expectation fulfill];
                        }
                    }];
                    // 5. Client A will reconnect
                    [_realtime connect];
                }];
            }
            else if (state == ARTRealtimeConnected) {
                // 1. Attach channel of Client A
                [channelA attach];
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
                [channel2 publish:nil data:message1 cb:^(ARTErrorInfo *errorInfo) {
                    [channel2 publish:nil data:message2 cb:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                    }];
                }];
            }
        }];
        [channel subscribe:^(ARTMessage * message) {
            NSString * msg = [message data];
            if([msg isEqualToString:message2]) {
                //disconnect connection1
                [_realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                [channel2 publish:nil data:message3 cb:^(ARTErrorInfo *errorInfo) {
                    [channel2 publish:nil data:message4 cb:^(ARTErrorInfo *errorInfo) {
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
