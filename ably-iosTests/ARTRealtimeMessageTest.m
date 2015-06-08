//
//  ARTRealtimeMessageTest.m
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
#import "ARTRealtime+Private.h"
#import "ARTPayload+Private.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"

@interface ARTRealtimeMessageTest : XCTestCase {
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end

@implementation ARTRealtimeMessageTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [ARTPayload getPayloadArraySizeLimit:SIZE_T_MAX modify:true];
    _realtime = nil;
    _realtime2 = nil;
}

- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay {
    __block int numReceived = 0;
    
    XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"multiple_send"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:name];
        [channel attach];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                [channel subscribe:^(ARTMessage *message) {
                    ++numReceived;
                    if (numReceived == count) {
                        [expectation fulfill];
                    }
                }];
                [ARTTestUtil repeat:count delay:(delay / 1000.0) block:^(int i) {
                    NSString *msg = [NSString stringWithFormat:@"Test message (_multiple_send) %d", i];
                    [channel publish:msg withName:@"test_event" cb:^(ARTStatus *status) { 
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:((delay / 1000.0) * count * 2) handler:nil];
}

- (void)testSingleSendText {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendText"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"testSingleSendText"];
        [channel subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], @"testString");
            [expectation fulfill];
        }];
        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testSingleSendEchoText {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"testSingleEcho";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        ARTRealtime * realtime1 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime1;
        ARTRealtimeChannel *channel = [realtime1 channel:channelName];
            [channel subscribe:^(ARTMessage * message) {
                XCTAssertEqualObjects([message content], @"testStringEcho");
                [expectation fulfill];
            }];
        ARTRealtime * realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = realtime2;
        ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
        [channel2 subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], @"testStringEcho");
        }];
        [channel2 publish:@"testStringEcho" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



- (void)testPublish_10_1000 {
    [self multipleSendName:@"multiple_send_10_1000" count:10 delay:1000];
}

- (void)testPublish_20_200 {
    [self multipleSendName:@"multiple_send_20_200" count:20 delay:200];
}

- (void)testMultipleText_1000_10 {
    [self multipleSendName:@"multiple_send_1000_10" count:1000 delay:10];
}


- (void)testEchoMessagesDefault {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEchoMessagesDefault"];
    NSString * channelName = @"channel";
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        __block bool gotMessage1 = false;
        [channel subscribe:^(ARTMessage * message) {
            if([[message content] isEqualToString:message1]) {
                gotMessage1 = true;
            }
            else {
                XCTAssertTrue(gotMessage1);
                XCTAssertEqualObjects([message content], message2);
                [exp fulfill];
            }
        }];
        [channel publish:message1 cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            ARTRealtimeChannel * channel2 = [_realtime2 channel:channelName];
            [channel2 publish:message2 cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEchoMessagesFalse {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEchoMessagesFalse"];
    NSString * channelName = @"channel";
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.echoMessages = false;
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        [channel subscribe:^(ARTMessage * message) {
            //message1 should never arrive
            XCTAssertEqualObjects([message content], message2);
            [exp fulfill];
        }];
        [channel publish:message1 cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            ARTRealtimeChannel * channel2 = [_realtime2 channel:channelName];
            [channel2 publish:message2 cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeAttaches {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendText"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"testSubscribeAttaches"];
        [channel subscribe:^(ARTMessage * message) {
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            XCTAssertEqual(ARTStatusOk, reason.status);
            if(cState == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }   
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testMessageQueue {
    XCTestExpectation *exp = [self expectationWithDescription:@"testMessageQueue"];
    NSString * connectingMessage = @"connectingMessage";
    NSString * disconnectedMessage = @"disconnectedMessage";

    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"testMessageQueue"];
        __block int messagesReceived = 0;
        [channel subscribe:^(ARTMessage * message) {
            //we receive connecting message twice. Once before disconnection and resume, and once after.
            if(messagesReceived ==0) {
                XCTAssertEqualObjects([message content], connectingMessage);
            }
            else if(messagesReceived ==1) {
                XCTAssertEqualObjects([message content], connectingMessage);
            }
            else if(messagesReceived ==2) {
                XCTAssertEqualObjects([message content], disconnectedMessage);
                [exp fulfill];
            }
            messagesReceived++;
        }];
        __block bool connectingHappened = false;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state ==ARTRealtimeConnecting) {
                if(connectingHappened) {
                    [channel attach];
                }
                else {
                    connectingHappened = true;
                    [channel publish:connectingMessage cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [realtime onDisconnected:nil];
                    }];
                }
            }
            else if(state == ARTRealtimeDisconnected) {
                [channel publish:disconnectedMessage cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
                [realtime connect];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testConnectionIdsInMessage {
    XCTestExpectation *exp = [self expectationWithDescription:@"testConnectionIdsInMessage"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        XCTAssertFalse([_realtime2.connectionKey isEqualToString:_realtime.connectionKey]);
        ARTRealtimeChannel *c1 = [_realtime channel:channelName];
        [c1 publish:@"message" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            ARTRealtimeChannel *c2 = [_realtime2 channel:channelName];
            [c2 publish:@"message2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [c1 history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(m0.connectionId, _realtime2.connectionId);
                    XCTAssertEqualObjects(m1.connectionId, _realtime.connectionId);
                    XCTAssertFalse([m0.connectionId isEqualToString:m1.connectionId]);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPublishImmediate {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishImmediate"];
    
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [_realtime channel:@"testSingleSendText"];
        [_realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publish:@"testString" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
        [channel subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], @"testString");
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPublishArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishArray"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        NSArray * messages = @[@"test1", @"test2", @"test3"];
        [channel publish:messages cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        __block int messageCount =0;
        [channel subscribe:^(ARTMessage * message) {
            if(messageCount ==0) {
                XCTAssertEqualObjects([message content], @"test1");
            }
            else if(messageCount ==1) {
                XCTAssertEqualObjects([message content], @"test2");
            }
            else if(messageCount ==2) {
                XCTAssertEqualObjects([message content], @"test3");
                [exp fulfill];
            }
            messageCount++;
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPublishWithName {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishWithName"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        [channel publish:@"test" withName:@"messageName" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        [channel subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects(message.content, @"test");
            XCTAssertEqualObjects(message.name, @"messageName");
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testSubscribeToName {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSubscribeToName"];
    NSString * channelName = @"channel";
    NSString * messageName =@"messageName";
    NSString * messageContent = @"content";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToName:messageName cb:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], messageContent);
            [exp fulfill];
        }];

        [channel publish:@"unnamed_wont_arrive" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publish:@"wrong_name_wont_arrive" withName:@"wrongName" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel publish:messageContent withName:messageName cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
