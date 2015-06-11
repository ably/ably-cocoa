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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTRest.h"
#import "ARTRealtime+Private.h"
#import "ARTPresenceMap.h"
#import "ARTLog.h"
#import "ARTCrypto.h"

@interface ARTRealtimePresenceTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
    ARTOptions * _options;
    ARTRest * _rest;
}
@end

@implementation ARTRealtimePresenceTest

- (void)setUp {
    [super setUp];

}

- (void)tearDown {
    _realtime = nil;
    _realtime2 = nil;
    [super tearDown];
}

-(NSString *) getClientId {
    return @"theClientId";
}

-(NSString *) getSecondClientId {
    return @"secondClientId";
}

- (void)withRealtimeClientId:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        ARTOptions * options = [ARTTestUtil jsonRealtimeOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options cb:^(ARTOptions *options) {
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


-(void) testTwoConnections {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"testSingleEcho";
    [self withRealtimeClientId:^(ARTRealtime *realtime1) {
        ARTRealtimeChannel *channel = [realtime1 channel:channelName];
        [channel subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], @"testStringEcho");
            [expectation fulfill];
        }];
        [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel2 subscribe:^(ARTMessage * message) {
                XCTAssertEqualObjects([message content], @"testStringEcho");
            }];
            [channel2 publish:@"testStringEcho" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



//TODO this is probably too wordy.
- (void)testEnterSimple {
    
    NSString * channelName = @"presTest";
    XCTestExpectation *dummyExpectation = [self expectationWithDescription:@"testEnterSimple"];
     [self withRealtimeClientId:^(ARTRealtime *realtime) {
         [dummyExpectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    NSString * presenceEnter = @"client_has_entered";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        XCTestExpectation *expectConnected = [self expectationWithDescription:@"expectConnected"];
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [expectConnected fulfill];
            }
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        ARTRealtimeChannel *channel2 = [realtime channel:channelName];
        [channel2 attach];
        [channel attach];
        XCTestExpectation *expectChannel2Connected = [self expectationWithDescription:@"presence message"];
        
        [channel2 subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [expectChannel2Connected fulfill];
            }
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectPresenceMessage = [self expectationWithDescription:@"presence message"];
        
        [channel2 subscribeToPresence:^(ARTPresenceMessage * message) {
            [expectPresenceMessage fulfill];
        
        }];
        [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
    
    
}

- (void) testEnterAttachesTheChannel {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAttachesTheChannel"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        XCTAssertEqual(channel.state, ARTRealtimeChannelInitialised);
        [channel publishPresenceEnter:@"entered" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            XCTAssertEqual(channel.state, ARTRealtimeChannelAttached);
            [exp fulfill];
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeConnects {
    NSString * channelName = @"presBeforeAttachTest";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
        }];
        
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testUpdateConnects {
    NSString * channelName = @"presBeforeAttachTest";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel publishPresenceUpdate:@"update"  cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterBeforeConnect {
    NSString * channelName = @"testEnterBeforeConnect";
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            XCTAssertEqualObjects([message content], presenceEnter);
            [expectation fulfill];
        }];
        
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterLeaveSimple {
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";
    NSString * presenceLeave = @"byebye";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceLeave:presenceLeave cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], presenceLeave);
                [expectation fulfill];
            }
        }];
        
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterEnter {
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";
    NSString * secondEnter = @"secondEnter";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceEnter:secondEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            else if(message.action == ARTPresenceMessageUpdate) {
                XCTAssertEqualObjects([message content], secondEnter);
                [expectation fulfill];
            }
        }];
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterUpdateSimple
{
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";
    NSString * update = @"updateMessage";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceUpdate:update cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            else if(message.action == ARTPresenceMessageUpdate) {
                XCTAssertEqualObjects([message content], update);
                [expectation fulfill];
            }
        }];
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testUpdateNull
{
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceUpdate:nil cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            else if(message.action == ARTPresenceMessageUpdate) {
                XCTAssertEqualObjects([message content], nil);
                [expectation fulfill];
            }
        }];
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterLeaveWithoutData {
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";

    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceLeave:nil cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [expectation fulfill];
            }
            
        }];
        
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testUpdateNoEnter {
    NSString * update = @"update_message";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testUpdateNoEnter"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], update);
                [expectation fulfill];
            }
        }];
        
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceUpdate:update cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



-(void) testEnterAndGet {
    NSString * enter = @"enter";
    NSString * enter2 = @"enter2";
    NSString * channelName = @"channelName";
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAndGet"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        [options setClientId:[self getSecondClientId]];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
        [channel publishPresenceEnter:enter cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel2 publishPresenceEnter:enter2 cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel2 presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTPresenceMessage *m0 = messages[0];
                    ARTPresenceMessage *m1 = messages[1];
                    XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects(enter2, [m0 content]);
                    XCTAssertEqual(m1.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects(enter, [m1 content]);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterNoClientId {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterNoClientId"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"testEnterNoClientId"];
        XCTAssertThrows([channel publishPresenceEnter:@"thisWillFail" cb:^(ARTStatus *status){}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterOnDetached {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"testEnterNoClientId"];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel detach];
            }
            else if(cState == ARTRealtimeChannelDetached) {
                [channel publishPresenceEnter:@"thisWillFail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterOnFailed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"testEnterNoClientId"];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel setFailed:[ARTStatus state:ARTStatusError]];
            }
            else if(cState == ARTRealtimeChannelFailed) {
                [channel publishPresenceEnter:@"thisWillFail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testFilterPresenceByClientId {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
           _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
            [channel2 publishPresenceEnter:@"hi2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel2 presenceGetWithParams:@{@"client_id" : [self getSecondClientId]} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(1, messages.count);
                    ARTPresenceMessage *m0 = messages[0];
                    XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects(@"hi2", [m0 content]);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testLeaveAndGet
{
    NSString * enter = @"enter";
    NSString * leave = @"bye";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterAndGet"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter)  {
                XCTAssertEqualObjects([message content], enter);
                [channel publishPresenceLeave:leave cb:^(ARTStatus *status) {
                    XCTAssertEqualObjects([message content], enter);
                    [channel presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        NSArray *messages = [result currentItems];
                        XCTAssertEqual(0, messages.count);
                        [expectation fulfill];
                    }];
                }];
            }
        }];
        
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:enter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testLeaveNoData
{
    NSString * enter = @"enter";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterLeaveNoData"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], enter);
                [channel publishPresenceLeave:nil cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            else if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], enter);
                [expectation fulfill];
            }
        }];
        
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceUpdate:enter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


-(void) testLeaveNoMessage
{
    NSString * enter = @"enter";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterAndGet"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter)  {
                XCTAssertEqualObjects([message content], enter);
                [channel publishPresenceLeave:nil cb:^(ARTStatus *status) {
                    XCTAssertEqualObjects([message content], enter);
                }];
            }
            if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], enter);
                [expectation fulfill];
            }
        }];
        [channel publishPresenceEnter:enter cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testLeaveWithMessage {
    NSString * enter = @"enter";
    NSString * leave = @"bye";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterAndGet"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter)  {
                XCTAssertEqualObjects([message content], enter);
                [channel publishPresenceLeave:leave cb:^(ARTStatus *status) {
                    XCTAssertEqualObjects([message content], enter);
                }];
            }
            if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], leave);
                [expectation fulfill];
            }
        }];
        [channel publishPresenceEnter:enter cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testLeaveOnDetached {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"testEnterNoClientId"];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel detach];
            }
            else if(cState == ARTRealtimeChannelDetached) {
                XCTAssertThrows([channel publishPresenceLeave:@"thisWillFail" cb:^(ARTStatus *status) {}]);
                [expectation fulfill];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testLeaveOnFailed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"testEnterNoClientId"];
        [channel subscribeToEventEmitter:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel setFailed:[ARTStatus state:ARTStatusError]];
            }
            else if(cState == ARTRealtimeChannelFailed) {
                XCTAssertThrows([channel publishPresenceLeave:@"thisWillFail" cb:^(ARTStatus *status) {}]);
                [expectation fulfill];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterFailsOnError {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterBeforeAttach"];
    NSString * channelName = @"presBeforeAttachTest";
    NSString * presenceEnter = @"client_has_entered";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime onError:nil];
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [exp fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testGetFailsOnDetachedOrFailed {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAndGet"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"channel"];
        __block bool hasDisconnected = false;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime onDisconnected:nil];
            }
            if(state == ARTRealtimeDisconnected) {
                hasDisconnected = true;
                XCTAssertThrows([channel presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {}]);
                [realtime onError:nil];
            }
            if(state == ARTRealtimeFailed) {
                XCTAssertTrue(hasDisconnected);
                XCTAssertThrows([channel presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {}]);
                [exp fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterClient {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterClient"];
    NSString * clientId = @"otherClientId";
    NSString * clientId2 = @"yetAnotherClientId";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"channelName"];
        [channel publishEnterClient:clientId data:nil cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publishEnterClient:clientId2 data:nil cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTPresenceMessage * m0 = [messages objectAtIndex:0];
                    XCTAssertEqualObjects(m0.clientId, clientId);
                    ARTPresenceMessage * m1 = [messages objectAtIndex:1];
                    XCTAssertEqualObjects(m1.clientId, clientId2);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterClientIdFailsOnError {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterClientIdFailsOnError"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"channelName"];
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime onError:nil];
                [channel publishEnterClient:@"clientId" data:nil cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [exp fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testWithNoClientIdUpdateLeaveEnterAnotherClient {
    XCTestExpectation *exp = [self expectationWithDescription:@"testWithNoClientIdUpdateLeaveEnterAnotherClient"];
    NSString * otherClientId = @"otherClientId";
    NSString * data = @"data";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = nil;
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:@"channelName"];
        [channel publishEnterClient:otherClientId data:nil cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publishUpdateClient:otherClientId data:data cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel publishLeaveClient:otherClientId data:nil cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }];
        }];
        
        __block int messageCount =0;
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            XCTAssertEqualObjects(otherClientId, message.clientId);
            if(messageCount ==0) {
                XCTAssertEqual(message.action, ARTPresenceMessageEnter);
                XCTAssertEqualObjects( message.content, nil);
            }
            else if(messageCount ==1) {
                XCTAssertEqual(message.action, ARTPresenceMessageUpdate);
                XCTAssertEqualObjects(message.content, data);
            }
            else if(messageCount ==2) {
                XCTAssertEqual(message.action, ARTPresenceMessageLeave);
                XCTAssertEqualObjects(message.content, data);
                [exp fulfill];
            }
            messageCount++;
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)test250ClientsEnter {
    
    XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    NSString * channelName = @"channelName";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        const int count =250;
        __block bool channel2SawAllPresences =false;
        XCTestExpectation *setupChannel2 = [self expectationWithDescription:@"setupChannel2"];
        [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
            _realtime2 = realtime2;
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            __block int numReceived = 0;
            [channel2 subscribeToEventEmitter:^(ARTRealtimeChannelState c, ARTStatus * s) {
                if(c == ARTRealtimeChannelAttached) {
                    //channel2 enters itself
                    [channel2 publishEnterClient:@"channel2Enter" data:@"joins" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [setupChannel2 fulfill];
                    }];
                }
            }];
            [channel2 subscribeToPresence:^(ARTPresenceMessage * message) {
                numReceived++;
                if(numReceived ==count +1) {//count + channel1
                    channel2SawAllPresences = true;
                }
            }];
            [channel2 attach];
        }];
        
        [ARTTestUtil bigSleep];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *enterAll = [self expectationWithDescription:@"enterAll"];
        //channel enters itself
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            //channel enters 250 others
            [ARTTestUtil publishEnterMessages:@"aClientId" count:count channel:channel expectation:enterAll];
                    }];
        [self waitForExpectationsWithTimeout:120 handler:nil];
        XCTestExpectation *getPresence = [self expectationWithDescription:@"getPresence"];
        [channel presenceGetWithParams:@{@"limit" : @"1000"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(ARTStatusOk, status.status);
            NSArray *messages = [result currentItems];
            XCTAssertEqual(count+2, messages.count);//count + channel1+ channel2
            XCTAssertTrue(channel2SawAllPresences);
            [getPresence fulfill];
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testPresenceMap {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceMap"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
        }];
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
            _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
            [channel2 presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                XCTAssertFalse([channel2 presenceSyncComplete]);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    XCTAssertTrue([channel2 presenceSyncComplete]);
                    ARTPresenceMap * map = channel2.presenceMap;
                    ARTPresenceMessage * m =[map getClient:[self getClientId]];
                    XCTAssertFalse(m == nil);
                    XCTAssertEqual(m.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects([m content], @"hi");
                    [exp fulfill];
                });
            }];
            [channel2 attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPresenceMapWaitOnSync {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceMap"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
        }];
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
            _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
            [channel2 presenceGetWithParams:@{@"wait_for_sync": @"true"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                ARTPresenceMap * map = channel2.presenceMap;
                ARTPresenceMessage * m =[map getClient:[self getClientId]];
                XCTAssertFalse(m == nil);
                XCTAssertEqual(m.action, ArtPresenceMessagePresent);
                XCTAssertEqualObjects([m content], @"hi");
                [exp fulfill];
            }];
            [channel2 attach];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



-(void) testLeaveBeforeEnterThrows {
    XCTestExpectation *exp = [self expectationWithDescription:@"testLeaveBeforeEnterThrows"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        XCTAssertThrows([channel publishPresenceLeave:nil cb:^(ARTStatus *status) {}]); // leave before enter
        [channel publishPresenceEnter:nil cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publishPresenceLeave:nil cb:^(ARTStatus *status) { //leave after enter
                XCTAssertEqual(ARTStatusOk, status.status);
                XCTAssertThrows([channel publishPresenceLeave:nil cb:^(ARTStatus *status) {}]); // leave after leave
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeToAction {
    NSString * channelName = @"presBeforeAttachTest";
    NSString * enter1 = @"enter1";
    NSString * update1 = @"update1";
    NSString * leave1 = @"leave1";
    XCTestExpectation *exp = [self expectationWithDescription:@"testSubscribeToAction"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        
        __block bool gotUpdate = false;
        __block bool gotEnter = false;
        __block bool gotLeave = false;
        id<ARTSubscription> allSub = [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            XCTAssertEqualObjects([message content], leave1);
            gotLeave = true;
        }];
        [channel unsubscribePresence:allSub action:ARTPresenceMessageEnter];
        [channel unsubscribePresence:allSub action:ARTPresenceMessageUpdate];
        id<ARTSubscription> updateSub=[channel subscribeToPresenceAction:ARTPresenceMessageUpdate cb:^(ARTPresenceMessage * message) {
            XCTAssertEqualObjects([message content], update1);
            gotUpdate = true;
        }];
        id<ARTSubscription> enterSub =[channel subscribeToPresenceAction:ARTPresenceMessageEnter cb:^(ARTPresenceMessage * message) {
            XCTAssertEqualObjects([message content], enter1);
            gotEnter = true;
        }];
        [channel publishPresenceEnter:enter1 cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publishPresenceUpdate:update1 cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel unsubscribePresence:updateSub];
                [channel unsubscribePresence:enterSub];
                [channel publishPresenceUpdate:@"noone will get this" cb:^(ARTStatus *status) {
                    [channel publishPresenceLeave:leave1 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel publishPresenceEnter:@"nor this" cb:^(ARTStatus *status) {
                            XCTAssertEqual(ARTStatusOk, status.status);
                            XCTAssertTrue(gotUpdate);
                            XCTAssertTrue(gotEnter);
                            XCTAssertTrue(gotLeave);
                            [exp fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSyncResumes {
    
    XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    NSString * channelName = @"channelName";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        const int count =120;
        
        XCTestExpectation *enterAll = [self expectationWithDescription:@"enterAll"];
        
        //channel enters itself
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            //channel enters all others
            [ARTTestUtil publishEnterMessages:@"aClientId" count:count channel:channel expectation:enterAll];
        }];
        
        
        [self waitForExpectationsWithTimeout:120 handler:nil];
        XCTestExpectation *setupChannel2 = [self expectationWithDescription:@"setupChannel2"];
        [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
            _realtime2 = realtime2;
            __block bool hasFailed = false;
          
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel2 subscribeToEventEmitter:^(ARTRealtimeChannelState c, ARTStatus * s) {
                if(c == ARTRealtimeChannelAttached) {
                    //channel2 enters itself
                    [channel2 publishEnterClient:@"channel2Enter" data:@"joins" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
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
                    [realtime2 onError:nil];
                }
                else if([channel2.presenceMap isSyncComplete] && !syncComplete) {
                    XCTAssertTrue(hasFailed);
                    [setupChannel2 fulfill];
                    syncComplete = true;
                }
            }];
            
            [realtime2 subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
                if(state == ARTRealtimeFailed) {
                    hasFailed = true;
                    [realtime2 connect];
                }
            }];
        }];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}


-(void) testPresenceNoSideEffects {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceNoSideEffects"];
    NSString * channelName = @"channelName";
    NSString * client1 = @"client1";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {}];
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publishEnterClient:client1 data:@"data" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel publishUpdateClient:client1 data:@"data2" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [channel publishLeaveClient:client1 data:@"data3" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                            XCTAssertEqual(ARTStatusOk, status.status);
                            XCTAssertEqual(ARTStatusOk, status.status);
                            NSArray *messages = [result currentItems];
                            XCTAssertEqual(1, messages.count);
                            //check channel hasnt changed its own state by changing presence of another clientId
                            ARTPresenceMessage *m0 = messages[0];
                            XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                            XCTAssertEqualObjects(m0.clientId, [self getClientId]);
                            XCTAssertEqualObjects([m0 content], @"hi");
                            [exp fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPresenceWithData {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceWithData"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        NSData * dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
        [channel publishPresenceEnter:dataPayload cb:^(ARTStatus *status) {
             XCTAssertEqual(ARTStatusOk, status.status);
            [channel presenceGet:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                NSArray *messages = [result currentItems];
                XCTAssertEqual(1, messages.count);
                ARTPresenceMessage *m0 = messages[0];
                XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                XCTAssertEqualObjects(m0.clientId, [self getClientId]);
                XCTAssertEqualObjects([m0 content], dataPayload);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPresenceWithDataOnLeave {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPresenceWithDataOnLeave"];
    NSString * channelName = @"channelName";
    NSData * dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        options.clientId = @"clientId2";
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
        [channel2 subscribeToPresence:^(ARTPresenceMessage * message) {
            NSLog(@"got message %@", message.content);
            if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], dataPayload);
                [exp fulfill];
            }
        }];
        [channel2 attach];
        [channel attach];
        [channel publishPresenceEnter:dataPayload cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publishPresenceLeave:nil cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testFilterPresenceByConnectionId {
    XCTestExpectation *exp = [self expectationWithDescription:@"testFilterPresenceByConnectionId"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel *channel = [_realtime channel:channelName];
        [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [options setClientId: [self getSecondClientId]];
            XCTAssertEqual(options.clientId, [self getSecondClientId]);
            _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            ARTRealtimeChannel *channel2 = [_realtime2 channel:channelName];
            [channel2 publishPresenceEnter:@"hi2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel2 presenceGetWithParams:@{@"connectionId" : _realtime.connectionId} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(1, messages.count);
                    ARTPresenceMessage *m0 = messages[0];
                    XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects(@"hi", [m0 content]);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


@end
