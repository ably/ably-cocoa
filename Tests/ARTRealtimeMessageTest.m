//
//  ARTRealtimeMessageTest.m
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
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTEventEmitter.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTNSArray+ARTFunctional.h"

@interface ARTRealtimeMessageTest : XCTestCase

@end

@implementation ARTRealtimeMessageTest

- (void)tearDown {
    [super tearDown];
}

- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];

    __block int numReceived = 0;
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:name];

    [channel attach];

    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel subscribe:^(ARTMessage *message) {
                ++numReceived;
                if (numReceived == count) {
                    [expectation fulfill];
                }
            }];
            [ARTTestUtil repeat:count delay:(delay / 1000.0) block:^(int i) {
                NSString *msg = [NSString stringWithFormat:@"Test message (_multiple_send) %d", i];
                [channel publish:@"test_event" data:msg callback:^(ARTErrorInfo *errorInfo) { 
                }];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:50.0 handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testSingleSendText {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testSingleSendText"];
    [channel subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], @"testString");
        [expectation fulfill];
    }];
    [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testSingleSendEchoText {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];

    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-1", __FUNCTION__]];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];
    __weak XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-3", __FUNCTION__]];
    NSString *channelName = @"testSingleEcho";
    
    ARTRealtime *realtime1 = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];

    ARTRealtimeChannel *channel = [realtime1.channels get:channelName];
    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

    __block NSUInteger attached = 0;
    // Channel 1
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached++;
        }
    }];

    // Channel 2
    [channel2 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached++;
        }
    }];

    [channel subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], @"testStringEcho");
        [expectation1 fulfill];
    }];


    [channel2 subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], @"testStringEcho");
        [expectation2 fulfill];
    }];

    [ARTTestUtil waitForWithTimeout:&attached list:@[channel, channel2] timeout:1.5];

    [channel2 publish:nil data:@"testStringEcho" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [expectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout]+5.0 handler:nil];
    [realtime1 testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

- (void)testPublish_10_1000 {
    [self multipleSendName:@"multiple_send_10_1000" count:10 delay:1000];
}

- (void)testMultipleText_1000_10 {
    [self multipleSendName:@"multiple_send_1000_10" count:1000 delay:10];
}

- (void)testEchoMessagesDefault {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];

    NSString *channelName = @"channel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    void(^partialDone)() = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:3];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];

    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    __block bool gotMessage1 = false;
    [channel subscribe:^(ARTMessage *message) {
        if ([[message data] isEqualToString:message1]) {
            gotMessage1 = true;
            partialDone();
        }
        else {
            XCTAssertTrue(gotMessage1);
            XCTAssertEqualObjects([message data], message2);
            partialDone();
        }
    }];
    [channel publish:nil data:message1 callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
        [channel2 publish:nil data:message2 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            partialDone();
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

- (void)testEchoMessagesFalse {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];

    NSString *channelName = @"channel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.echoMessages = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel subscribe:^(ARTMessage *message) {
        //message1 should never arrive
        XCTAssertEqualObjects([message data], message2);
        [expectation fulfill];
    }];
    [channel publish:nil data:message1 callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
        [channel2 publish:nil data:message2 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

- (void)testSubscribeAttaches {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testSubscribeAttaches"];
    [channel subscribe:^(ARTMessage *message) {
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        XCTAssert(!stateChange.reason);
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectation fulfill];
        }   
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testMessageQueue {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];

    NSString *connectingMessage = @"connectingMessage";
    NSString *disconnectedMessage = @"disconnectedMessage";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.autoConnect = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testMessageQueue"];
    __block int messagesReceived = 0;
    [channel subscribe:^(ARTMessage *message) {
        if(messagesReceived ==0) {
            XCTAssertEqualObjects([message data], connectingMessage);
        }
        else if(messagesReceived ==1) {
            XCTAssertEqualObjects([message data], disconnectedMessage);
            [expectation fulfill];
        }
        messagesReceived++;
    }];
    __block bool connectingHappened = false;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if(state ==ARTRealtimeConnecting) {
            if(connectingHappened) {
                [channel attach];
            }
            else {
                connectingHappened = true;
                [channel publish:nil data:connectingMessage callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [realtime onDisconnected];
                }];
            }
        }
        else if(state == ARTRealtimeDisconnected) {
            [channel publish:nil data:disconnectedMessage callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
            [realtime connect];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testConnectionIdsInMessage {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"channelName";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    XCTAssertFalse([realtime2.connection.key isEqualToString:realtime.connection.key]);
    ARTRealtimeChannel *c1 = [realtime.channels get:channelName];
    [c1 publish:nil data:@"message" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        ARTRealtimeChannel *c2 = [realtime2.channels get:channelName];
        [c2 publish:nil data:@"message2" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [c1 history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                XCTAssert(!error);
                NSArray *messages = [result items];
                XCTAssertEqual(2, messages.count);
                ARTMessage *m0 = messages[0];
                ARTMessage *m1 = messages[1];
                XCTAssertEqualObjects(m0.data, @"message2");
                XCTAssertEqualObjects(m1.data, @"message");
                XCTAssertEqualObjects(m0.connectionId, realtime2.connection.id);
                XCTAssertEqualObjects(m1.connectionId, realtime.connection.id);
                XCTAssertFalse([m0.connectionId isEqualToString:m1.connectionId]);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

- (void)testPublishImmediate {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testSingleSendText"];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if(state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [channel subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], @"testString");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testPublishArray {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
    NSArray *messages = [@[@"test1", @"test2", @"test3"] artMap:^id(id data) {
        return [[ARTMessage alloc] initWithName:nil data:data];
    }];
    [channel publish:messages callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    __block int messageCount =0;
    [channel subscribe:^(ARTMessage *message) {
        if(messageCount ==0) {
            XCTAssertEqualObjects([message data], @"test1");
        }
        else if(messageCount ==1) {
            XCTAssertEqualObjects([message data], @"test2");
        }
        else if(messageCount ==2) {
            XCTAssertEqualObjects([message data], @"test3");
            [expectation fulfill];
        }
        messageCount++;
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testPublishWithName {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
    [channel publish:@"messageName" data:@"test" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [channel subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects(message.data, @"test");
        XCTAssertEqualObjects(message.name, @"messageName");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testSubscribeToName {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"channel";
    NSString *messageName =@"messageName";
    NSString *messageContent = @"content";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel subscribe:messageName callback:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], messageContent);
        [expectation fulfill];
    }];

    [channel publish:nil data:@"unnamed_wont_arrive" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [channel publish:@"wrongName" data:@"wrong_name_wont_arrive" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel publish:messageName data:messageContent callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

@end
