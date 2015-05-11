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
#import "ARTLog.h"

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
                [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime) {
                    _realtime = realtime;
                    [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime2) {
                        _realtime2 = realtime2;
                        cb(_realtime);
                    }];
                }];
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


-(void) testTwoConnections
{
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
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
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
        
        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testEnterEnter
{
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
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
            
            if(message.action == ARTPresenceMessageEnter)
            {
                XCTAssertEqualObjects([message content], update);
                [expectation fulfill];
            }
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
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
        [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime1) {
            _realtime = realtime1;
            [options setClientId:[self getSecondClientId]];
            [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime2) {
                _realtime2 = realtime2;
                ARTRealtimeChannel *channel = [realtime1 channel:channelName];
                ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
                [channel publishPresenceEnter:enter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [channel2 publishPresenceEnter:enter2 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel2 presence:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                            XCTAssertEqual(ARTStatusOk, status.status);
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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




-(void) testFilterPresenceByClientId
{
    XCTestExpectation *exp = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"testSingleEcho";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime1) {
            _realtime = realtime1;
            ARTRealtimeChannel *channel = [realtime1 channel:channelName];
            [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [options setClientId: [self getSecondClientId]];
                XCTAssertEqual(options.clientId, [self getSecondClientId]);
                [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime2) {
                    _realtime2 = realtime2;
                    ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
                    [channel2 publishPresenceEnter:@"hi2" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel2 presenceWithParams:@{@"clientId" : [self getSecondClientId]} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                            XCTAssertEqual(ARTStatusOk, status.status);
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
                    [channel presence:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        NSArray *messages = [result currentItems];
                        XCTAssertEqual(0, messages.count);
                        [expectation fulfill];
                    }];
                }];
            }
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
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

-(void) testLeaveWithMessage
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel detach];
            }
            else if(cState == ARTRealtimeChannelDetached) {
                [channel publishPresenceLeave:@"thisWillFail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [expectation fulfill];
                }];
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel setFailed:[ARTStatus state:ARTStatusError]];
            }
            else if(cState == ARTRealtimeChannelFailed) {
                [channel publishPresenceLeave:@"thisWillFail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testLeaveConnects {
    NSString * channelName = @"presBeforeAttachTest";
    NSString * presenceLeave = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel publishPresenceLeave:presenceLeave cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [expectation fulfill];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testEnterFailsOnError {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterBeforeAttach"];
    NSString * channelName = @"presBeforeAttachTest";
    NSString * presenceEnter = @"client_has_entered";
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime onError:nil];

                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [exp fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


-(void) testSyncMessageOnExistingMember
{
    XCTFail(@"this test needs to show that sync was called on channel1, with channel2's info");
    XCTestExpectation *exp = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"channelName";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.clientId = [self getClientId];
        [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime1) {
            _realtime = realtime1;
            ARTRealtimeChannel *channel = [realtime1 channel:channelName];
            [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            }];
            [channel publishPresenceEnter:@"hi" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [options setClientId: [self getSecondClientId]];
                XCTAssertEqual(options.clientId, [self getSecondClientId]);
                [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime2) {
                    _realtime2 = realtime2;
                    ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];

                    [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
                        if(cState == ARTRealtimeChannelAttached) {
                            //TODO exp doesnt belong here.
                            [exp fulfill];
                        
                        }
                    }];
                    [channel2 attach];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testGetFailsOnDetachedOrFailed {
    XCTestExpectation *exp = [self expectationWithDescription:@"testEnterAndGet"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"channel"];
        __block bool hasDisconnected = false;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime onDisconnected:nil];
            }
            if(state == ARTRealtimeDisconnected) {
                hasDisconnected = true;
                XCTAssertThrows([channel presence:^(ARTStatus *status, id<ARTPaginatedResult> result) {}]);
                [realtime onError:nil];
            }
            if(state == ARTRealtimeFailed) {
                XCTAssertTrue(hasDisconnected);
                XCTAssertThrows([channel presence:^(ARTStatus *status, id<ARTPaginatedResult> result) {}]);
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
                [channel presence:^(ARTStatus *status, id<ARTPaginatedResult> result) {
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
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
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
        [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime) {
            _realtime = realtime;
            ARTRealtimeChannel *channel = [realtime channel:@"channelName"];
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
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


@end
