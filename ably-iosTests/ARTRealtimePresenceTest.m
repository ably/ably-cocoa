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
//#import "ARTRealtime+Private.h"

@interface ARTRealtimePresenceTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
    
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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(NSString *) getClientId
{
    return @"theClientId";
}
- (void)withRealtimeClientId:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        ARTOptions * options = [ARTTestUtil jsonRealtimeOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}

- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}

- (void)withRealtimeClientId2:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime2) {
        ARTOptions * options = [ARTTestUtil jsonRealtimeOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options cb:^(ARTOptions *options) {
            if (options) {
                _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime2);
        }];
        return;
    }
    cb(_realtime2);
}


//TODO RM
/*
-(void) testWtfTwoChannels
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"testSingleEcho";
    [self withRealtimeClientId:^(ARTRealtime *realtime1) {
        ARTRealtimeChannel *channel = [realtime1 channel:channelName];
        [channel subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], @"testStringEcho");
            NSLog(@"recieved testStringEcho!!");
            [expectation fulfill];
        }];
        
        [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel2 subscribe:^(ARTMessage * message) {
                XCTAssertEqualObjects([message content], @"testStringEcho");
            }];
            [channel2 publish:@"testStringEcho" cb:^(ARTStatus status) {
                XCTAssertEqual(ARTStatusOk, status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
*/


//TODO this is probably too wordy.
//enter_simple
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
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [expectConnected fulfill];
            }
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        NSLog(@"channeling");
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        ARTRealtimeChannel *channel2 = [realtime channel:channelName];
        [channel2 attach];
        [channel attach];
        XCTestExpectation *expectChannel2Connected = [self expectationWithDescription:@"presence message"];
        
        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                NSLog(@"cstate win");
                [expectChannel2Connected fulfill];
            }
            
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        NSLog(@"presinging ");
        XCTestExpectation *expectPresenceMessage = [self expectationWithDescription:@"presence message"];
        
        [channel2 subscribeToPresence:^(ARTPresenceMessage * message) {
            NSLog(@"presence2 message receieved %@", message);
            [expectPresenceMessage fulfill];
        
        }];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            NSLog(@"presence message receieved %@", message);
            //[expectPresenceMessage fulfill];
            
        }];
        NSLog(@"about to publish endtr");
        [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
            NSLog(@"published enter");
            XCTAssertEqual(ARTStatusOk, status);
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
            if (state == ARTRealtimeChannelAttached) {
                NSLog(@"publishing here we goooo");
               
            }
        }];
       
        NSLog(@"weaiting for presnece mesag");
         [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        NSLog(@"job done");
        
    }];
    
    
}

//enter_before_attach
- (void)testEnterBeforeAttach {

    NSString * channelName = @"presBeforeAttachTest";
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {

        
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            NSLog(@"pres recieved %@ conID %@", [message content], message.connectionId);
            XCTAssertEqualObjects([message content], presenceEnter);
            [expectation fulfill];
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
        
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//enter_before_connect
- (void)testEnterBeforeConnect {
    NSString * channelName = @"testEnterBeforeConnect";
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            NSLog(@"pres recieved %@ conID %@", [message content], message.connectionId);
            XCTAssertEqualObjects([message content], presenceEnter);
            [expectation fulfill];
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//enter_leave_simple
- (void)testEnterLeaveSimple {
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";
    NSString * presenceLeave = @"byebye";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            
            if(message.action == ARTPresenceMessageEnter)
            {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceLeave:presenceLeave cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            if(message.action == ARTPresenceMessageLeave)
            {
                XCTAssertEqualObjects([message content], presenceLeave);
                [expectation fulfill];
            }

        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//enter_enter_simple
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
                [channel publishPresenceEnter:secondEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


//enter_update_simple
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
                [channel publishPresenceUpdate:update cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
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
                [channel publishPresenceUpdate:nil cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
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
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//enter_leave_nodata
-(void) testEnterLeaveWithoutData {
    NSString * channelName = @"testEnterLeaveSimple";
    NSString * presenceEnter = @"client_has_entered";

    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], presenceEnter);
                [channel publishPresenceLeave:nil cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], presenceEnter);
                NSLog(@"WIN");
                [expectation fulfill];
            }
            
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//update_noenter
-(void) testUpdateNoEnter
{
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
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceUpdate:update cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
//enter_leave_nodata
-(void) testEnterLeaveNoData
{
    NSString * enter = @"enter";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterLeaveNoData"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter) {
                XCTAssertEqualObjects([message content], enter);
                [channel publishPresenceLeave:nil cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            else if(message.action == ARTPresenceMessageLeave) {
                XCTAssertEqualObjects([message content], enter);
                [expectation fulfill];
            }
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceUpdate:enter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//realtime_get_simple
-(void) testEnterAndGet
{
    NSString * enter = @"enter";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterAndGet"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter)  {
                XCTAssertEqualObjects([message content], enter);
                [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status);
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(1, messages.count);
                    ARTPresenceMessage *m0 = messages[0];
                    
                    XCTAssertEqual(m0.action, ArtPresenceMessagePresent);
                    XCTAssertEqualObjects(enter, [m0 content]);
                    [expectation fulfill];
                }];
            }
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:enter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//realtime_get_leave
-(void) testEnterLeaveAndGet
{
    NSString * enter = @"enter";
    NSString * leave = @"bye";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testEnterAndGet"];
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            if(message.action == ARTPresenceMessageEnter)  {
                XCTAssertEqualObjects([message content], enter);
                
                [channel publishPresenceLeave:leave cb:^(ARTStatus status) {
                    XCTAssertEqualObjects([message content], enter);
                    [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(ARTStatusOk, status);
                        XCTAssertEqual(status, ARTStatusOk);
                        NSArray *messages = [result current];
                        XCTAssertEqual(0, messages.count);
                        NSLog(@"no messages %@", messages);
                        [expectation fulfill];
                    }];
                }];
            }
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:enter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
//attach_enter_simple
- (void)testAttachEnterTwoConnections {
    XCTFail(@"needs realtime2");
}

//attach_enter_simple
- (void)testAttachEnterSimple {
    XCTFail(@"needs realtime2");
}

//attach_enter_multiple
- (void)testAttachEnterMultiple {
    XCTFail(@"TODO write test");
}

//realtime_enter_multiple
- (void)testRealtimeEnterMultiple {
    XCTFail(@"TODO write test");
}



//requires rest as well i guess
//rest_get_simple
-(void) testRestEnterGet
{
    XCTFail(@"needs realtime2");
    return;
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    
    //TODO do some raeltime stuff then check the rest channel sees the same noise.
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"restTest"];
        [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            if(status != ARTStatusOk) {
                XCTFail(@"not an ok status");
                [expectation fulfill];
                return;
            }
            NSArray *presence = [result current];
            XCTAssertEqual(4, presence.count);
            ARTPresenceMessage *p0 = presence[0];
            ARTPresenceMessage *p1 = presence[1];
            ARTPresenceMessage *p2 = presence[2];
            ARTPresenceMessage *p3 = presence[3];
            

            
            // This is assuming the results are coming back sorted by clientId
            // in alphabetical order. This seems to be the case at the time of
            // writing, but may change in the future
            
            XCTAssertEqualObjects(@"client_bool", p0.clientId);
            XCTAssertEqualObjects(@"true", [p0 content]);
            
            XCTAssertEqualObjects(@"client_int", p1.clientId);
            XCTAssertEqualObjects(@"24", [p1 content]);
            
            XCTAssertEqualObjects(@"client_json", p2.clientId);
            XCTAssertEqualObjects(@"{\"test\":\"This is a JSONObject clientData payload\"}", [p2 content]);
            
            XCTAssertEqualObjects(@"client_string", p3.clientId);
            XCTAssertEqualObjects(@"This is a string clientData payload", [p3 content]);
            
            
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}

//rest_get_leave
- (void)testRestGetLeave {
    XCTFail(@"TODO write test");
}

//rest_enter_multiple
- (void)testRestEnterMultiple {
    XCTFail(@"TODO write test");
}

//rest_paginated_get
- (void)testRestPaginatedGet {
    XCTFail(@"TODO write test");
}

//disconnect_leave
//requires 2 connections...
- (void)testDisconnectLeave {
        XCTFail(@"TODO write test");
    /*
    NSString * enter = @"enter";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testUpdateNoEnter"];
        __block bool  hasEntered = false;
        [channel subscribeToPresence:^(ARTPresenceMessage * message) {
            
            NSLog(@"channel got message %@", [message content]);
            if(message.action == ARTPresenceMessageEnter)
            {
                hasEntered =true;
                XCTAssertEqualObjects([message content], enter);
                //[realtime onError:nil];
                [realtime close];
            }
            if(message.action ==  ARTPresenceMessageLeave)
            {
                XCTAssert(hasEntered);
                [expectation fulfill];
            }
        }];
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached)
            {
                [channel publishPresenceEnter:enter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                }];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
     */
}


/* msgpack not implemented yet
- (void)testMultipleBinary {
    XCTFail(@"TODO write test");
}

 */

@end
