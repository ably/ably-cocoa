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

@interface ARTRealtimeMessageTest : XCTestCase {
    ARTRealtime *_realtime;
    ARTRealtime *_realtime2;
}

@end

@implementation ARTRealtimeMessageTest

- (void)tearDown {
    [super tearDown];
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
}

- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay {
    __block int numReceived = 0;
    
    __weak XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    [_realtime close];

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"multiple_send"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:name];

        [channel attach];

        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
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
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout]+delay handler:nil];
}

- (void)testSingleSendText {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendText"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"testSingleSendText"];
        [channel subscribe:^(ARTMessage *message) {
            XCTAssertEqualObjects([message data], @"testString");
            [expectation fulfill];
        }];
        [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSingleSendEchoText {
    __weak XCTestExpectation *exp1 = [self expectationWithDescription:@"testSingleSendEchoText1"];
    __weak XCTestExpectation *exp2 = [self expectationWithDescription:@"testSingleSendEchoText2"];
    __weak XCTestExpectation *exp3 = [self expectationWithDescription:@"testSingleSendEchoText3"];
    NSString *channelName = @"testSingleEcho";
    
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        ARTRealtime *realtime1 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime1;
        ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = realtime2;

        ARTRealtimeChannel *channel = [realtime1.channels get:channelName];
        ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

        __block NSUInteger attached = 0;
        // Channel 1
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                attached++;
            }
        }];

        // Channel 2
        [channel2 on:^(ARTErrorInfo *errorInfo) {
            if (channel2.state == ARTRealtimeChannelAttached) {
                attached++;
            }
        }];

        [channel subscribe:^(ARTMessage *message) {
            XCTAssertEqualObjects([message data], @"testStringEcho");
            [exp1 fulfill];
        }];


        [channel2 subscribe:^(ARTMessage *message) {
            XCTAssertEqualObjects([message data], @"testStringEcho");
            [exp2 fulfill];
        }];

        [ARTTestUtil waitForWithTimeout:&attached list:@[channel, channel2] timeout:1.5];

        [channel2 publish:nil data:@"testStringEcho" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [exp3 fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublish_10_1000 {
    [self multipleSendName:@"multiple_send_10_1000" count:10 delay:1000];
}

- (void)testMultipleText_1000_10 {
    [self multipleSendName:@"multiple_send_1000_10" count:1000 delay:10];
}

- (void)testEchoMessagesDefault {
    NSString *channelName = @"channel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";

    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEchoMessagesDefault"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        __block bool gotMessage1 = false;
        [channel subscribe:^(ARTMessage *message) {
            if([[message data] isEqualToString:message1]) {
                gotMessage1 = true;
            }
            else {
                XCTAssertTrue(gotMessage1);
                XCTAssertEqualObjects([message data], message2);
                [exp fulfill];
            }
        }];
        [channel publish:nil data:message1 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
            [channel2 publish:nil data:message2 callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEchoMessagesFalse {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEchoMessagesFalse"];
    NSString *channelName = @"channel";
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";
    
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.echoMessages = false;
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        [channel subscribe:^(ARTMessage *message) {
            //message1 should never arrive
            XCTAssertEqualObjects([message data], message2);
            [exp fulfill];
        }];
        [channel publish:nil data:message1 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
            [channel2 publish:nil data:message2 callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeAttaches {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendText"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"testSubscribeAttaches"];
        [channel subscribe:^(ARTMessage *message) {
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            XCTAssert(!errorInfo);
            if(channel.state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }   
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testMessageQueue {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testMessageQueue"];
    NSString *connectingMessage = @"connectingMessage";
    NSString *disconnectedMessage = @"disconnectedMessage";
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.autoConnect = false;
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"testMessageQueue"];
        __block int messagesReceived = 0;
        [channel subscribe:^(ARTMessage *message) {
            if(messagesReceived ==0) {
                XCTAssertEqualObjects([message data], connectingMessage);
            }
            else if(messagesReceived ==1) {
                XCTAssertEqualObjects([message data], disconnectedMessage);
                [exp fulfill];
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
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testConnectionIdsInMessage {
    NSString *channelName = @"channelName";
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testConnectionIdsInMessage"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        XCTAssertFalse([_realtime2.connection.key isEqualToString:_realtime.connection.key]);
        ARTRealtimeChannel *c1 = [_realtime.channels get:channelName];
        [c1 publish:nil data:@"message" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            ARTRealtimeChannel *c2 = [_realtime2.channels get:channelName];
            [c2 publish:nil data:@"message2" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [c1 history:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(m0.data, @"message2");
                    XCTAssertEqualObjects(m1.data, @"message");
                    XCTAssertEqualObjects(m0.connectionId, _realtime2.connection.id);
                    XCTAssertEqualObjects(m1.connectionId, _realtime.connection.id);
                    XCTAssertFalse([m0.connectionId isEqualToString:m1.connectionId]);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishImmediate {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPublishImmediate"];
    
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [_realtime.channels get:@"testSingleSendText"];
        [_realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if(state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
        [channel subscribe:^(ARTMessage *message) {
            XCTAssertEqualObjects([message data], @"testString");
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishArray {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPublishArray"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
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
                [exp fulfill];
            }
            messageCount++;
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishWithName {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPublishWithName"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
        [channel publish:@"messageName" data:@"test" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
        [channel subscribe:^(ARTMessage *message) {
            XCTAssertEqualObjects(message.data, @"test");
            XCTAssertEqualObjects(message.name, @"messageName");
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testSubscribeToName {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testSubscribeToName"];
    NSString *channelName = @"channel";
    NSString *messageName =@"messageName";
    NSString *messageContent = @"content";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel subscribe:messageName callback:^(ARTMessage *message) {
            XCTAssertEqualObjects([message data], messageContent);
            [exp fulfill];
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
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
