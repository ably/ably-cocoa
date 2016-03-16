//
//  ARTRealtimePresenceTest.m
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
#import "ARTRealtimeChannel+Private.h"
#import "ARTPaginatedResult.h"
#import "ARTEventEmitter.h"
#import "ARTTestUtil.h"
#import "ARTRest.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimePresence.h"
#import "ARTPresenceMap.h"
#import "ARTLog.h"
#import "ARTCrypto.h"

@interface ARTRealtimePresenceTest : XCTestCase {
    ARTRealtime *_realtime;
    ARTRealtime *_realtime2;
    ARTClientOptions *_options;
    ARTRest *_rest;
}

@end

@implementation ARTRealtimePresenceTest

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

- (NSString *)getClientId {
    return @"theClientId";
}

- (NSString *)getSecondClientId {
    return @"secondClientId";
}

- (void)withRealtimeClientId:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        ARTClientOptions *options = [ARTTestUtil clientOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options callback:^(ARTClientOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
                _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
                cb(_realtime);
            }
        }];
        return;
    }
    else {
        cb(_realtime);
    }
}

//only for use after withRealtimeClientId.
- (void)withRealtimeClientId2:(void (^)(ARTRealtime *realtime))cb {
    cb(_realtime2);
}

- (void)testTwoConnections {
    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:@"testTwoConnections1"];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:@"testTwoConnections2"];
    __weak XCTestExpectation *expectation3 = [self expectationWithDescription:@"testTwoConnections3"];
    NSString *channelName = @"testSingleEcho";
    [self withRealtimeClientId:^(ARTRealtime *realtime1) {
        [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
            ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
            ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];

            __block NSUInteger attached = 0;
            // Channel 1
            [channel on:^(ARTErrorInfo *errorInfo) {
                if (channel.state == ARTRealtimeChannelAttached) {
                    attached++;
                }
            }];
            // Channel 2
            [channel2 on:^(ARTErrorInfo *errorInfo) {
                if (channel.state == ARTRealtimeChannelAttached) {
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
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterSimple {
    NSString *channelName = @"presTest";
    __weak XCTestExpectation *dummyExpectation = [self expectationWithDescription:@"testEnterSimple"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        [dummyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    NSString *presenceEnter = @"client_has_entered";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        __weak XCTestExpectation *expectConnected = [self expectationWithDescription:@"expectConnected"];

        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [expectConnected fulfill];
            }
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        ARTRealtimeChannel *channel2 = [realtime.channels get:channelName];
        [channel2 attach];
        [channel attach];
        __weak XCTestExpectation *expectChannel2Connected = [self expectationWithDescription:@"presence message"];

        [channel2 on:^(ARTErrorInfo *errorInfo) {
            if(channel2.state == ARTRealtimeChannelAttached) {
                [expectChannel2Connected fulfill];
            }
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        __weak XCTestExpectation *expectPresenceMessage = [self expectationWithDescription:@"presence message"];

        [channel2.presence subscribe:^(ARTPresenceMessage *message) {
            [expectPresenceMessage fulfill];

        }];
        [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

- (void)testEnterAttachesTheChannel {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAttachesTheChannel"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
        XCTAssertEqual(channel.state, ARTRealtimeChannelInitialized);
        [channel.presence enter:@"entered" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            XCTAssertEqual(channel.state, ARTRealtimeChannelAttached);
            [exp fulfill];
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeConnects {
    NSString *channelName = @"presBeforeAttachTest";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
        }];
        
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testUpdateConnects {
    NSString *channelName = @"presBeforeAttachTest";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence update:@"update"  callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterBeforeConnect {
    NSString *channelName = @"testEnterBeforeConnect";
    NSString *presenceEnter = @"client_has_entered";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            XCTAssertEqualObjects([message data], presenceEnter);
            [expectation fulfill];
        }];
        
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached)
            {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterLeaveSimple {
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    NSString *presenceLeave = @"byebye";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], presenceEnter);
                [channel.presence leave:presenceLeave callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            if(message.action == ARTPresenceLeave) {
                XCTAssertEqualObjects([message data], presenceLeave);
                [expectation fulfill];
            }
        }];
        
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterEnter {
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    NSString *secondEnter = @"secondEnter";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], presenceEnter);
                [channel.presence enter:secondEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            else if(message.action == ARTPresenceUpdate) {
                XCTAssertEqualObjects([message data], secondEnter);
                [expectation fulfill];
            }
        }];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterUpdateSimple
{
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    NSString *update = @"updateMessage";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], presenceEnter);
                [channel.presence update:update callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            else if(message.action == ARTPresenceUpdate) {
                XCTAssertEqualObjects([message data], update);
                [expectation fulfill];
            }
        }];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testUpdateNull {
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], presenceEnter);
                [channel.presence update:nil callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            else if(message.action == ARTPresenceUpdate) {
                XCTAssertEqualObjects([message data], nil);
                [expectation fulfill];
            }
        }];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterLeaveWithoutData {
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], presenceEnter);
                [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            if(message.action == ARTPresenceLeave) {
                XCTAssertEqualObjects([message data], presenceEnter);
                [expectation fulfill];
            }
            
        }];
        
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testUpdateNoEnter {
    NSString *update = @"update_message";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testUpdateNoEnter"];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], update);
                [expectation fulfill];
            }
        }];
        
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence update:update callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterAndGet {
    NSString *enterData = @"online";
    NSString *channelName = @"test";
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAndGet"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        [options setClientId:[self getSecondClientId]];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
        [channel.presence enter:enterData callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel2.presence enter:enterData callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [channel2.presence get:^(NSArray<ARTPresenceMessage *> *members, ARTErrorInfo *error) {
                    XCTAssert(!error);
                    XCTAssertEqual(2, members.count);
                    XCTAssertEqual(members[0].action, ARTPresencePresent);
                    XCTAssertEqual(members[1].action, ARTPresenceEnter);
                    XCTAssertEqualObjects([members[0] data], enterData);
                    XCTAssertEqualObjects([members[1] data], enterData);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterNoClientId {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterNoClientId"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
        [channel.presence enter:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo){
            XCTAssertNotNil(errorInfo);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterOnDetached {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel detach];
            }
            else if(channel.state == ARTRealtimeChannelDetached) {
                [channel.presence enter:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNotNil(errorInfo);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterOnFailed {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel setFailed:[ARTStatus state:ARTStateError]];
            }
            else if(channel.state == ARTRealtimeChannelFailed) {
                [channel.presence enter:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNotNil(errorInfo);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//TODO wortk out why presence with clientId doesnt work
/*
- (void)testFilterPresenceByClientId {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString *channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        [channel.presence publishPresenceEnter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
           _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
            [channel2.presence publishPresenceEnter:@"hi2" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [channel2.presence getWithParams:@{@"client_id" : [self getSecondClientId]} callback:^(ARTErrorInfo *errorInfo, id<ARTPaginatedResult> result) {
                    XCTAssertNil(errorInfo);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(1, messages.count);
                    ARTPresenceMessage *m0 = messages[0];
                    XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects(@"hi2", [m0 data]);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
 */

- (void)testLeaveAndGet {
    NSString *enterData = @"enter";
    NSString *leaveData = @"bye";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterAndGet"];
        [channel.presence subscribe:^(ARTPresenceMessage * message) {
            if (message.action == ARTPresenceEnter)  {
                XCTAssertEqualObjects([message data], enterData);
                [channel.presence leave:leaveData callback:^(ARTErrorInfo *error) {
                    XCTAssert(!error);
                    [channel.presence get:^(NSArray *members, ARTErrorInfo *error) {
                        XCTAssert(!error);
                        XCTAssertEqual(0, members.count);
                        [expectation fulfill];
                    }];
                }];
            }
        }];

        [channel.presence enter:enterData callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testLeaveNoData {
    NSString *enter = @"enter";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterLeaveNoData"];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter) {
                XCTAssertEqualObjects([message data], enter);
                [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            else if(message.action == ARTPresenceLeave) {
                XCTAssertEqualObjects([message data], enter);
                [expectation fulfill];
            }
        }];
        
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached)
            {
                [channel.presence update:enter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testLeaveNoMessage {
    NSString *enter = @"enter";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterAndGet"];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter)  {
                XCTAssertEqualObjects([message data], enter);
                [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertEqualObjects([message data], enter);
                }];
            }
            if(message.action == ARTPresenceLeave) {
                XCTAssertEqualObjects([message data], enter);
                [expectation fulfill];
            }
        }];
        [channel.presence enter:enter callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testLeaveWithMessage {
    NSString *enter = @"enter";
    NSString *leave = @"bye";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterAndGet"];
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            if(message.action == ARTPresenceEnter)  {
                XCTAssertEqualObjects([message data], enter);
                [channel.presence leave:leave callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertEqualObjects([message data], enter);
                }];
            }
            if(message.action == ARTPresenceLeave) {
                XCTAssertEqualObjects([message data], leave);
                [expectation fulfill];
            }
        }];
        [channel.presence enter:enter callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testLeaveOnDetached {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel detach];
            }
            else if(channel.state == ARTRealtimeChannelDetached) {
                XCTAssertThrows([channel.presence leave:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {}]);
                [expectation fulfill];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testLeaveOnFailed {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel setFailed:[ARTStatus state:ARTStateError]];
            }
            else if(channel.state == ARTRealtimeChannelFailed) {
                XCTAssertThrows([channel.presence leave:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {}]);
                [expectation fulfill];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterFailsOnError {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterBeforeAttach"];
    NSString *channelName = @"presBeforeAttachTest";
    NSString *presenceEnter = @"client_has_entered";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if(state == ARTRealtimeConnected) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNotNil(errorInfo);
                    [exp fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testGetFailsOnDetachedOrFailed {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAndGet"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
        __block bool hasDisconnected = false;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if(state == ARTRealtimeConnected) {
                [realtime onDisconnected];
            }
            else if(state == ARTRealtimeDisconnected) {
                hasDisconnected = true;
                XCTAssertThrows([channel.presence get:^(NSArray *result, ARTErrorInfo *error) {}]);
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else if(state == ARTRealtimeFailed) {
                XCTAssertTrue(hasDisconnected);
                XCTAssertThrows([channel.presence get:^(NSArray *result, ARTErrorInfo *error) {}]);
                [exp fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterClient {
    NSString *clientId = @"otherClientId";
    NSString *clientId2 = @"yetAnotherClientId";

    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterClient"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"channelName"];
        [channel.presence enterClient:clientId data:nil callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence  enterClient:clientId2 data:nil callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [channel.presence get:^(NSArray *members, ARTErrorInfo *error) {
                    XCTAssert(!error);
                    XCTAssertEqual(2, members.count);
                    ARTPresenceMessage *m0 = [members objectAtIndex:0];
                    XCTAssertEqualObjects(m0.clientId, clientId2);
                    ARTPresenceMessage *m1 = [members objectAtIndex:1];
                    XCTAssertEqualObjects(m1.clientId, clientId);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterClientIdFailsOnError {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testEnterClientIdFailsOnError"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"channelName"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if(state == ARTRealtimeConnected) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                [channel.presence  enterClient:@"clientId" data:@"" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNotNil(errorInfo);
                    [exp fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testWithNoClientIdUpdateLeaveEnterAnotherClient {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testWithNoClientIdUpdateLeaveEnterAnotherClient"];
    NSString *otherClientId = @"otherClientId";
    NSString *data = @"data";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = nil;
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:@"channelName"];
        [channel.presence  enterClient:otherClientId data:@"" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence updateClient:otherClientId data:data callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [channel.presence leaveClient:otherClientId data:@"" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }];
        }];
        
        __block int messageCount =0;
        [channel.presence subscribe:^(ARTPresenceMessage *message) {
            XCTAssertEqualObjects(otherClientId, message.clientId);
            if(messageCount ==0) {
                XCTAssertEqual(message.action, ARTPresenceEnter);
                XCTAssertEqualObjects(message.data, @"");
            }
            else if(messageCount ==1) {
                XCTAssertEqual(message.action, ARTPresenceUpdate);
                XCTAssertEqualObjects(message.data, data);
            }
            else if(messageCount ==2) {
                XCTAssertEqual(message.action, ARTPresenceLeave);
                XCTAssertEqualObjects(message.data, data);
                [exp fulfill];
            }
            messageCount++;
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
- (void)test250ClientsEnter {
    NSString *channelName = @"channelName";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"setupChannel2"];
    ARTClientOptions *options =[ARTTestUtil clientOptions];
    options.clientId = @"client_string";

    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        const int count = 250;
        __block bool channel2SawAllPresences = false;

        [ARTTestUtil testRealtime:^(ARTRealtime *realtime2) {
            _realtime2 = realtime2;
            ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
            __block int numReceived = 0;

            [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState c, ARTStatus *s) {
                if (c == ARTRealtimeChannelAttached) {
                    //channel2 enters itself
                    [channel2.presence enterClient:@"channel2Enter" data:@"joins" callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);

                        [ARTTestUtil bigSleep];

                        //channel enters itself
                        [channel.presence enter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNil(errorInfo);
                            //channel enters 250 others
                            [ARTTestUtil publishEnterMessages:@"aClientId" count:count channel:channel completion:^{
                                [channel.presence get:^(ARTPaginatedResult *result, NSError *error) {
                                    XCTAssert(!error);
                                    NSArray *messages = [result items];
                                    XCTAssertEqual(count+2, messages.count); //count + channel1+ channel2
                                    XCTAssertTrue(channel2SawAllPresences);
                                    [expectation fulfill];
                                }];
                            }];
                        }];
                    }];
                }
            }];
            [channel2.presence subscribe:^(ARTPresenceMessage *message) {
                numReceived++;
                if (numReceived == count +1) {//count + channel1
                    channel2SawAllPresences = true;
                }
            }];
            [channel2 attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
*/

- (void)testPresenceMap {
    NSString * channelName = @"channelName";
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceMap"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        [channel.presence enter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
            _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
            [channel2.presence get:^(NSArray *members, ARTErrorInfo *error) {
                XCTAssert(!error);
                XCTAssertFalse(channel2.presence.syncComplete);
                [ARTTestUtil delay:1.0 block:^{
                    XCTAssertTrue(channel2.presence.syncComplete);
                    ARTPresenceMap *map = channel2.presenceMap;
                    ARTPresenceMessage *m = [map.members objectForKey:[self getClientId]];
                    XCTAssertFalse(m == nil);
                    XCTAssertEqual(m.action, ARTPresencePresent);
                    XCTAssertEqualObjects([m data], @"hi");
                    [exp fulfill];
                }];
            }];
            [channel2 attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//TODO work out why wait_for_sync doesnt work
/*
- (void)testPresenceMapWaitOnSync {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceMap"];
    NSString *channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        [channel.presence subscribeToPresence:^(ARTPresenceMessage *message) {
        }];
        [channel.presence publishPresenceEnter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
            _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
            [channel2.presence getWithParams:@{@"wait_for_sync": @"true"} callback:^(ARTErrorInfo *errorInfo, id<ARTPaginatedResult> result) {
                XCTAssertNil(errorInfo);
                ARTPresenceMap *map = channel2.presenceMap;
                ARTPresenceMessage *m =[map getClient:[self getClientId]];
                XCTAssertFalse(m == nil);
                XCTAssertEqual(m.action, ArtPresenceMessagePresent);
                XCTAssertEqualObjects([m data], @"hi");
                [exp fulfill];
            }];
            [channel2 attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
*/

- (void)testLeaveBeforeEnterThrows {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testLeaveBeforeEnterThrows"];
    NSString *channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        XCTAssertThrows([channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {}]); // leave before enter
        [channel.presence enter:nil callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) { //leave after enter
                XCTAssertNil(errorInfo);
                XCTAssertThrows([channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {}]); // leave after leave
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeToAction {
    NSString *channelName = @"presBeforeAttachTest";
    NSString *enter1 = @"enter1";
    NSString *update1 = @"update1";
    NSString *leave1 = @"leave1";
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testSubscribeToAction"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        
        __block bool gotUpdate = false;
        __block bool gotEnter = false;
        __block bool gotLeave = false;
        ARTEventListener *leaveSub = [channel.presence subscribe:ARTPresenceLeave callback:^(ARTPresenceMessage *message) {
            XCTAssertEqualObjects([message data], leave1);
            gotLeave = true;
        }];
        ARTEventListener *updateSub=[channel.presence subscribe:ARTPresenceUpdate callback:^(ARTPresenceMessage *message) {
            XCTAssertEqualObjects([message data], update1);
            gotUpdate = true;
        }];
        ARTEventListener *enterSub =[channel.presence subscribe:ARTPresenceEnter callback:^(ARTPresenceMessage *message) {
            XCTAssertEqualObjects([message data], enter1);
            gotEnter = true;
        }];
        [channel.presence enter:enter1 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence update:update1 callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [channel.presence unsubscribe:updateSub];
                [channel.presence unsubscribe:enterSub];
                [channel.presence update:@"noone will get this" callback:^(ARTErrorInfo *errorInfo) {
                    [channel.presence leave:leave1 callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel.presence enter:@"nor this" callback:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNil(errorInfo);
                            XCTAssertTrue(gotUpdate);
                            XCTAssertTrue(gotEnter);
                            XCTAssertTrue(gotLeave);
                            [channel.presence unsubscribe:leaveSub];
                            [exp fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
- (void)testSyncResumes {
    NSString *channelName = @"channelName";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"enterAll"];
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.clientId = @"client_string";

    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];

        const int count = 120;
        
        //channel enters itself
        [channel.presence enter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            //channel enters all others
            [ARTTestUtil publishEnterMessages:@"aClientId" count:count channel:channel completion:^{
                [ARTTestUtil testRealtime:^(ARTRealtime *realtime2) {
                    _realtime2 = realtime2;
                    __block bool hasFailed = false;

                    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
                    [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState c, ARTStatus *s) {
                        if(c == ARTRealtimeChannelAttached) {
                            //channel2 enters itself
                            [channel2.presence enterClient:@"channel2Enter" data:@"joins" callback:^(ARTErrorInfo *errorInfo) {
                                XCTAssertNil(errorInfo);
                            }];
                        }
                    }];

                    [channel2 attach];

                    __block bool firstSyncMessageReceived = false;
                    __block bool syncComplete = false;

                    [channel2.presenceMap onSync:^{
                        if(!firstSyncMessageReceived) {
                            XCTAssertFalse([channel2.presenceMap isSyncComplete]); //confirm we still have more syncing to do.
                            firstSyncMessageReceived = true;
                            [realtime2 onError:[ARTTestUtil newErrorProtocolMessage]];
                        }
                        else if([channel2.presenceMap isSyncComplete] && !syncComplete) {
                            XCTAssertTrue(hasFailed);
                            [expectation fulfill];
                            syncComplete = true;
                        }
                    }];

                    [realtime2 on:^(ARTConnectionStateChange *stateChange) {
                        ARTRealtimeConnectionState state = stateChange.current;
                        ARTErrorInfo *errorInfo = stateChange.reason;
                        if(state == ARTRealtimeFailed) {
                            hasFailed = true;
                            [realtime2 connect];
                        }
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
*/

- (void)testPresenceNoSideEffects {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceNoSideEffects"];
    NSString *channelName = @"channelName";
    NSString *client1 = @"client1";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        [channel.presence enter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);

            [ARTTestUtil testRealtime:^(ARTRealtime *realtime2) {
                _realtime2 = realtime2;
                ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];
                [channel2.presence enterClient:client1 data:@"data" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [channel2.presence updateClient:client1 data:@"data2" callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel2.presence leaveClient:client1 data:@"data3" callback:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNil(errorInfo);
                            [channel.presence get:^(NSArray<ARTPresenceMessage *> *members, ARTErrorInfo *error) {
                                XCTAssert(!error);
                                XCTAssertEqual(1, members.count);
                                //check channel hasnt changed its own state by changing presence of another clientId
                                XCTAssertEqual(members[0].action, ARTPresenceEnter);
                                XCTAssertEqualObjects(members[0].clientId, [self getClientId]);
                                XCTAssertEqualObjects([members[0] data], @"hi");
                                [exp fulfill];
                            }];
                        }];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPresenceWithData {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceWithData"];
    NSString *channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
        [channel.presence enter:@"someDataPayload" callback:^(ARTErrorInfo *errorInfo) {
             XCTAssertNil(errorInfo);
            [channel.presence get:^(NSArray<ARTPresenceMessage *> *members, ARTErrorInfo *error) {
                XCTAssert(!error);
                XCTAssertEqual(1, members.count);
                XCTAssertEqual(members[0].action, ARTPresenceEnter);
                XCTAssertEqualObjects(members[0].clientId, [self getClientId]);
                XCTAssertEqualObjects([members[0] data], @"someDataPayload");
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPresenceWithDataOnLeave {
    __weak XCTestExpectation *exp1 = [self expectationWithDescription:@"testPresenceWithDataOnLeave1"];
    __weak XCTestExpectation *exp2 = [self expectationWithDescription:@"testPresenceWithDataOnLeave2"];
    NSString *channelName = @"channelName";
    NSData *dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime.channels get:channelName];

        options.clientId = @"clientId2";
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel2 = [_realtime2.channels get:channelName];

        [channel2.presence subscribe:^(ARTPresenceMessage *message) {
            if (message.action == ARTPresenceLeave) {
                XCTAssertEqualObjects([message data], dataPayload);
                [exp1 fulfill];
            }
        }];

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

        [channel2 attach];
        [channel attach];

        [ARTTestUtil waitForWithTimeout:&attached list:@[channel, channel2] timeout:1.5];

        // Presence
        [channel.presence enter:dataPayload callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [exp2 fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
