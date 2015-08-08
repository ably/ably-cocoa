//
//  ARTRealtimePresenceHistory.m
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
#import "ARTTestUtil.h"
#import "ARTRest.h"
#import "ARTLog.h"
@interface ARTRealtimePresenceHistoryTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
    ARTRealtime * _realtime3;
}
@end

@implementation ARTRealtimePresenceHistoryTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _realtime = nil;
    _realtime2 = nil;
    _realtime3 = nil;
    [super tearDown];
}
-(NSString *) getClientId {
    return @"theClientId";
}

- (void)withRealtimeClientId:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        ARTClientOptions * options = [ARTTestUtil jsonRealtimeOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options cb:^(ARTClientOptions *options) {
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

//only for use after withRealtimeClientId.
- (void)withRealtimeClientId2:(void (^)(ARTRealtime *realtime))cb {
    cb(_realtime2);
}

-(NSString *) enter1Str {
    return @"client_entered1";
}

-(NSString *) enter2Str {
    return @"client_entered2";
}

-(NSString *) updateStr {
    return @"client_updated";
}

-(NSString *) channelName {
    return @"persisted:runTestChannelName";
}

-(void) runTestLimit:(int) limit forwards:(bool) forwards cb:(ARTPaginatedResultCb) cb
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:[self channelName]];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel.presence enter:[self enter1Str] cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    //second enter gets treated as an update.
                    [channel.presence enter:[self enter2Str] cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel.presence update:[self updateStr] cb:^(ARTStatus *status2) {
                            XCTAssertEqual(ARTStatusOk, status2.status);
                            NSString * dirStr = forwards ? @"forwards" : @"backwards";
                            NSString * limitStr = [NSString stringWithFormat:@"%d", limit];
                            [channel.presence historyWithParams:@{
                                                                 @"direction" : dirStr,
                                                                 @"limit" : limitStr}
                                                            cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                                                cb(status, result);
                                                                [expectation fulfill];
                                                            }];
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testPresenceHistory {
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testSimpleText"];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [channel.presence history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        NSArray *messages = [result currentItems];
                        XCTAssertEqual(1, messages.count);
                        ARTPresenceMessage *m0 = messages[0];
                        XCTAssertEqualObjects(presenceEnter, [m0 content]);
                           [expectation fulfill];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testForward {
    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testSimpleText"];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter1 cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [channel.presence enter:presenceEnter2 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel.presence update:presenceUpdate cb:^(ARTStatus *status2) {
                            XCTAssertEqual(ARTStatusOk, status2.status);
                            [channel.presence historyWithParams:@{@"direction" :@"forwards"} cb:^
                             (ARTStatus *status, id<ARTPaginatedResult> result) {
                                 XCTAssertEqual(ARTStatusOk, status.status);
                                 NSArray *messages = [result currentItems];
                                 XCTAssertEqual(3, messages.count);
                                 ARTPresenceMessage *m0 = messages[0];
                                 ARTPresenceMessage *m1 = messages[1];
                                 ARTPresenceMessage *m2 = messages[2];
                                 
                                 XCTAssertEqual(m0.action, ARTPresenceMessageEnter);
                                 XCTAssertEqualObjects(presenceEnter1, [m0 content]);
    
                                 XCTAssertEqualObjects(presenceEnter2, [m1 content]);
                                 XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
                                 XCTAssertEqualObjects(presenceUpdate, [m2 content]);
                                 XCTAssertEqual(m2.action, ARTPresenceMessageUpdate);
                                 [expectation fulfill];
                            }];
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSecondChannel {

    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    NSString * channelName = @"testSecondChannel";

    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendEchoText"];
    [self withRealtimeClientId:^(ARTRealtime *realtime1) {
        ARTRealtimeChannel *channel = [realtime1 channel:channelName];
       
    
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState1, ARTStatus *reason1) {
            if(cState1 == ARTRealtimeChannelAttached)
            {
                [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
                    ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
                    [channel2.presence enter:presenceEnter1 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel.presence enter:presenceEnter2 cb:^(ARTStatus *status) {
                            XCTAssertEqual(ARTStatusOk, status.status);
                            [channel2.presence update:presenceUpdate cb:^(ARTStatus *status) {
                                XCTAssertEqual(ARTStatusOk, status.status);
                                [channel.presence historyWithParams:@{@"direction" :@"forwards"} cb:^
                                 (ARTStatus *status, id<ARTPaginatedResult> result) {
                                     XCTAssertEqual(ARTStatusOk, status.status);
                                     NSArray *messages = [result currentItems];
                                     XCTAssertEqual(3, messages.count);
                                     ARTPresenceMessage *m0 = messages[0];
                                     ARTPresenceMessage *m1 = messages[1];
                                     ARTPresenceMessage *m2 = messages[2];
                                     
                                     XCTAssertEqual(m0.action, ARTPresenceMessageEnter);
                                     XCTAssertEqualObjects(presenceEnter1, [m0 content]);
                                     
                                     XCTAssertEqualObjects(presenceEnter2, [m1 content]);
                                     XCTAssertEqual(m1.action, ARTPresenceMessageEnter);
                                     XCTAssertEqualObjects(presenceUpdate, [m2 content]);
                                     XCTAssertEqual(m2.action, ARTPresenceMessageUpdate);
                                     [expectation fulfill];
                                 }];
                            }];
                            
                        }];
                    }];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



- (void)testWaitTextBackward {
    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testWaitTextBackward"];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter1 cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);

                    [channel.presence enter:presenceEnter2 cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel.presence update:presenceUpdate cb:^(ARTStatus *status2) {
                            XCTAssertEqual(ARTStatusOk, status2.status);
                            [channel.presence historyWithParams:@{@"direction" :@"backwards"} cb:^
                             (ARTStatus *status, id<ARTPaginatedResult> result) {
                                 XCTAssertEqual(ARTStatusOk, status.status);
                                 NSArray *messages = [result currentItems];
                                 XCTAssertEqual(3, messages.count);
                                 ARTPresenceMessage *m0 = messages[0];
                                 ARTPresenceMessage *m1 = messages[1];
                                 ARTPresenceMessage *m2 = messages[2];
                                 
                                 XCTAssertEqual(m0.action, ARTPresenceMessageUpdate);
                                 XCTAssertEqualObjects(presenceUpdate, [m0 content]);
                                 
                                 XCTAssertEqualObjects(presenceEnter2, [m1 content]);
                                 XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
                                 XCTAssertEqualObjects(presenceEnter1, [m2 content]);
                                 XCTAssertEqual(m2.action, ARTPresenceMessageEnter);
                                 [expectation fulfill];
                             }];
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}






-(void) testLimitForward
{
    [self runTestLimit:2 forwards:true cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
        XCTAssertEqual(ARTStatusOk, status.status);
        NSArray *messages = [result currentItems];
        XCTAssertEqual(2, messages.count);
        XCTAssert([result hasNext]);
        ARTPresenceMessage *m0 = messages[0];
        ARTPresenceMessage *m1 = messages[1];
        
        XCTAssertEqual(m0.action, ARTPresenceMessageEnter);
        XCTAssertEqualObjects([self enter1Str], [m0 content]);
        
        XCTAssertEqualObjects([self enter2Str], [m1 content]);
        XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
        
        [result next:^(ARTStatus *status, id<ARTPaginatedResult> result2) {
            
            NSArray *messages = [result2 currentItems];
            XCTAssertEqual(1, messages.count);
            XCTAssertFalse([result2 hasNext]);
            ARTPresenceMessage *m0 = messages[0];
            XCTAssertEqualObjects([self updateStr], [m0 content]);
            XCTAssertEqual(m0.action, ARTPresenceMessageUpdate);
        }];
    }];
}



- (void)testLimitBackward {
    [self runTestLimit:2 forwards:false cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
        XCTAssertEqual(ARTStatusOk, status.status);
        NSArray *messages = [result currentItems];
        XCTAssertEqual(2, messages.count);
        XCTAssert([result hasNext]);
        ARTPresenceMessage *m0 = messages[0];
        ARTPresenceMessage *m1 = messages[1];
        
        XCTAssertEqual(m0.action, ARTPresenceMessageUpdate);
        XCTAssertEqualObjects([self updateStr], [m0 content]);
        
        XCTAssertEqualObjects([self enter2Str], [m1 content]);
        XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
        
        [result next:^(ARTStatus *status, id<ARTPaginatedResult> result2) {
            
            NSArray *messages = [result2 currentItems];
            XCTAssertEqual(1, messages.count);
            XCTAssertFalse([result2 hasNext]);
            ARTPresenceMessage *m0 = messages[0];
            XCTAssertEqualObjects([self enter1Str], [m0 content]);
            XCTAssertEqual(m0.action, ARTPresenceMessageEnter);
        }];
    }];
}



-(int) firstBatchSize
{
    return 2;
}
-(int) secondBatchSize
{
    return 3;
}
-(int) thirdBatchSize
{
    return 4;
}


//TOOD consider using a pattern similar to ARTTestUtil testPublish.
-(void) runTestTimeForwards:(bool) forwards limit:(int) limit cb:(ARTPaginatedResultCb) cb
{
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    __block long long timeOffset= 0;
    
    [self withRealtimeClientId:^(ARTRealtime  *realtime) {
        [realtime time:^(ARTStatus *status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status.status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            
        }];
        [e fulfill];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testWaitText"];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        XCTestExpectation * firstBatchExpectation= [self expectationWithDescription:@"firstBatchExpectation"];
        
        int firstBatchTotal = [self firstBatchSize];
        int secondBatchTotal = [self secondBatchSize];
        int thirdBatchTotal = [self thirdBatchSize];
    
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel.presence enter:[self enter1Str] cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);

                    __block int numReceived=0;
                    for(int i=0;i < firstBatchTotal; i++)
                    {
                        NSString * str = [NSString stringWithFormat:@"update%d", i];
                        [channel.presence update:str cb:^(ARTStatus *status) {
                            XCTAssertEqual(ARTStatusOk, status.status);
                            sleep([ARTTestUtil smallSleep]);
                            numReceived++;
                            if(numReceived == firstBatchTotal) {
                                [firstBatchExpectation fulfill];
                            }
                        }];
                    }
                }];
            }
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation * secondBatchExpectation= [self expectationWithDescription:@"secondBatchExpectation"];
        
        
        
        long long start = [ARTTestUtil nowMilli]+ timeOffset;
        sleep([ARTTestUtil bigSleep]);
        
        __block int numReceived=0;
        for(int i=0;i < secondBatchTotal; i++) {
            NSString * str = [NSString stringWithFormat:@"second_updates%d", i];
            [channel.presence update:str cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                sleep([ARTTestUtil smallSleep]);
                numReceived++;
                if(numReceived == secondBatchTotal) {
                    [secondBatchExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation * thirdBatchExpectation= [self expectationWithDescription:@"thirdBatchExpectation"];
        
        sleep([ARTTestUtil bigSleep]);
        long long end = [ARTTestUtil nowMilli] +timeOffset;
        numReceived=0;
        for(int i=0;i < thirdBatchTotal; i++) {
            NSString * str = [NSString stringWithFormat:@"third_updates%d", i];
            [channel.presence update:str cb:^(ARTStatus *status) {
                sleep([ARTTestUtil smallSleep]);
                XCTAssertEqual(ARTStatusOk, status.status);
                numReceived++;
                if(numReceived == thirdBatchTotal) {
                    [thirdBatchExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation * historyExpecation= [self expectationWithDescription:@"historyExpecation"];
        [channel.presence historyWithParams:@{
                                      @"start" : [NSString stringWithFormat:@"%lld", start],
                                      @"end"   : [NSString stringWithFormat:@"%lld", end],
                                      @"limit" : [NSString stringWithFormat:@"%d", limit],
                                      @"direction" : (forwards ? @"forwards" : @"backwards")}
                                 cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                     cb(status, result);
                                     [historyExpecation fulfill];
                                 }];
         [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
    }];
}

- (void)testTimeForward {
    
    [self runTestTimeForwards:true limit:100 cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
        XCTAssertEqual(ARTStatusOk, status.status);
        XCTAssertFalse([result hasNext]);
        NSArray * page = [result currentItems];
        XCTAssertTrue(page != nil);
        XCTAssertEqual([page count], [self secondBatchSize]);
        for(int i=0;i < [page count]; i++) {
            NSString * goalStr = [NSString stringWithFormat:@"second_updates%d",i];
            ARTPresenceMessage * m = [page objectAtIndex:i];
            XCTAssertEqual(ARTPresenceMessageUpdate, m.action);
            XCTAssertEqualObjects(goalStr, [m content]);
        }
    }];
}
- (void)testTimeBackward {
    [self runTestTimeForwards:false limit:100 cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
        XCTAssertEqual(ARTStatusOk, status.status);
        XCTAssertFalse([result hasNext]);
        NSArray * page = [result currentItems];
        XCTAssertTrue(page != nil);
        XCTAssertEqual([page count], [self secondBatchSize]);
        int topSize = [self secondBatchSize];
        for(int i=0;i < [page count]; i++) {
            NSString * goalStr = [NSString stringWithFormat:@"second_updates%d",topSize - i -1];
            ARTPresenceMessage * m = [page objectAtIndex:i];
            XCTAssertEqual(ARTPresenceMessageUpdate, m.action);
            XCTAssertEqualObjects(goalStr, [m content]);
        }
    }];
}



- (void)testFromAttach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:[self channelName]];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel.presence enter:[self enter1Str] cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [channel.presence enter:[self enter2Str] cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [channel.presence update:[self updateStr] cb:^(ARTStatus *status2) {
                            XCTAssertEqual(ARTStatusOk, status2.status);
                            [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
                                ARTRealtimeChannel * channel2 = [realtime2 channel:[self channelName]];
                                [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
                                    if(cState == ARTRealtimeChannelAttached) {
                                        [channel2.presence historyWithParams:@{@"direction" : @"forwards"}
                                                                   cb:^(ARTStatus *status2, id<ARTPaginatedResult> c2Result) {
                                            XCTAssertEqual(ARTStatusOk,status2.status);
                                            NSArray *messages = [c2Result currentItems];
                                            XCTAssertEqual(3, messages.count);
                                            XCTAssertFalse([c2Result hasNext]);
                                            ARTPresenceMessage *m0 = messages[0];
                                            ARTPresenceMessage *m1 = messages[1];
                                            ARTPresenceMessage *m2 = messages[2];
                                            
                                            XCTAssertEqual(m0.action, ARTPresenceMessageEnter);
                                            XCTAssertEqualObjects([self enter1Str], [m0 content]);
                                            
                                            XCTAssertEqualObjects([self enter2Str], [m1 content]);
                                            XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
                                            XCTAssertEqualObjects([self updateStr], [m2 content]);
                                            XCTAssertEqual(m2.action, ARTPresenceMessageUpdate);
                                            [expectation fulfill];
                                        }];
                                    }
                                }];
                                [channel2 attach];
                            }];
                           
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}

- (void)testPresenceHistoryMultipleClients {
    NSString * presenceEnter1 = @"enter1";
    NSString * presenceEnter2 = @"enter2";
    NSString * presenceEnter3 = @"enter3";
    
    NSString * channelName = @"chanName";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime3 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel * c1 =[_realtime channel:channelName];
        [c1.presence enter:presenceEnter1 cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            ARTRealtimeChannel * c2 =[_realtime2 channel:channelName];
            [c2.presence enter:presenceEnter2 cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                ARTRealtimeChannel * c3 =[_realtime3 channel:channelName];
                [c3.presence enter:presenceEnter3 cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [c1.presence history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        NSArray *messages = [result currentItems];
                        XCTAssertEqual(3, messages.count);
                        {
                            ARTPresenceMessage *m = messages[0];
                            XCTAssertEqualObjects(presenceEnter3, [m content]);
                        }
                        {
                            ARTPresenceMessage *m = messages[1];
                            XCTAssertEqualObjects(presenceEnter2, [m content]);
                        }
                        {
                            ARTPresenceMessage *m = messages[2];
                            XCTAssertEqualObjects(presenceEnter1, [m content]);
                        }
                        [expectation fulfill];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
 //msgpack not implemented yet
- (void)testTypesBinary {
    XCTFail(@"TODO write test");
}


- (void)testWaitBinary {
    XCTFail(@"TODO write test");
}

- (void)testSimpleBinary {
    XCTFail(@"TODO write test");
}

- (void)testWaitBinaryForward {
    XCTFail(@"TODO write test");
}

- (void)testMixedBinaryBackward {
    XCTFail(@"TODO write test");
}

- (void)testMixedBinaryForward {
    XCTFail(@"TODO write test");
}

 */

@end
