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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTRest.h"

@interface ARTRealtimePresenceHistoryTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
    ARTRest * _rest;
}
@end

@implementation ARTRealtimePresenceHistoryTest

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

- (void)withRealtimeClientId:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        ARTOptions * options = [ARTTestUtil jsonRealtimeOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options cb:^(ARTOptions *options) {
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

-(NSString *) enter1Str
{
    return @"client_entered1";
}
-(NSString *) enter2Str
{
    return @"client_entered2";
}
-(NSString *) updateStr
{
    return @"client_updated";
}
-(void) runTestLimit:(int) limit forwards:(bool) forwards cb:(ARTPaginatedResultCb) cb
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:runTestLimit"];
        ARTRealtimeChannel *channel2 = [realtime channel:@"persisted:runTestLimit"];
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
                [channel2 attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:[self enter1Str] cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    NSLog(@"enter1");
                    [channel2 publishPresenceEnter:[self enter2Str] cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        NSLog(@"enter2");
                        [channel2 publishPresenceUpdate:[self updateStr] cb:^(ARTStatus status2) {
                            NSLog(@"update");
                            XCTAssertEqual(ARTStatusOk, status2);
                            
                            NSString * dirStr = forwards ? @"forwards" : @"backwards";
                            NSString * limitStr = [NSString stringWithFormat:@"%d", limit];
                            [channel presenceHistoryWithParams:@{
                                                                 @"direction" : dirStr,
                                                                 @"limit" : limitStr}
                                                            cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
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


- (void)testSimpleText {
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testSimpleText"];
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    [channel presenceHistory:^(ARTStatus status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(status, ARTStatusOk);
                        NSArray *messages = [result current];
                        NSLog(@"messages are %@", messages);
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
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter1 cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    NSLog(@"enter1");
                    [channel publishPresenceEnter:presenceEnter2 cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        NSLog(@"enter1");
                        [channel publishPresenceUpdate:presenceUpdate cb:^(ARTStatus status2) {
                                            NSLog(@"enter2");
                            XCTAssertEqual(ARTStatusOk, status2);
                            [channel presenceHistoryWithParams:@{@"direction" :@"forwards"} cb:^
                             (ARTStatus status, id<ARTPaginatedResult> result) {
                                 XCTAssertEqual(status, ARTStatusOk);
                                 NSArray *messages = [result current];
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
       
    
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState1, ARTStatus reason1) {
            if(cState1 == ARTRealtimeChannelAttached)
            {
                [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
                    ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
                    [channel2 publishPresenceEnter:presenceEnter1 cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        [channel publishPresenceEnter:presenceEnter2 cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
                            [channel2 publishPresenceUpdate:presenceUpdate cb:^(ARTStatus status) {
                                NSLog(@"done sending events on chanel2");
                                XCTAssertEqual(ARTStatusOk, status);
                                [channel presenceHistoryWithParams:@{@"direction" :@"forwards"} cb:^
                                 (ARTStatus status, id<ARTPaginatedResult> result) {
                                     XCTAssertEqual(status, ARTStatusOk);
                                     NSArray *messages = [result current];
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

/*
- (void)testSecondChannel {
    
    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    NSString * channelName = @"testSecondChannel";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                if (state == ARTRealtimeConnected) {
                    [channel attach];
                }
            }];
            [realtime2 subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                if (state == ARTRealtimeConnected) {
                    [channel attach];
                    [channel2 attach];
                }
            }];
            [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
                if(cState == ARTRealtimeChannelAttached) {
                    [channel publishPresenceEnter:presenceEnter1 cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        NSLog(@"enter1");
                        [channel2 publishPresenceEnter:presenceEnter2 cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
                            NSLog(@"enter2");
                            [channel2 publishPresenceUpdate:presenceUpdate cb:^(ARTStatus status2) {
                                NSLog(@"update");
                                XCTAssertEqual(ARTStatusOk, status2);
                                [channel2 presenceHistoryWithParams:@{@"direction" :@"forwards"} cb:^
                                 (ARTStatus status, id<ARTPaginatedResult> result) {
                                     XCTAssertEqual(status, ARTStatusOk);
                                     NSArray *messages = [result current];
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
                }
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
 */

- (void)testWaitTextBackward {
    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testWaitTextBackward"];
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:presenceEnter1 cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    NSLog(@"enter1");
                    [channel publishPresenceEnter:presenceEnter2 cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        NSLog(@"enter1");
                        [channel publishPresenceUpdate:presenceUpdate cb:^(ARTStatus status2) {
                            NSLog(@"enter2");
                            XCTAssertEqual(ARTStatusOk, status2);
                            [channel presenceHistoryWithParams:@{@"direction" :@"backwards"} cb:^
                             (ARTStatus status, id<ARTPaginatedResult> result) {
                                 XCTAssertEqual(status, ARTStatusOk);
                                 NSArray *messages = [result current];
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
    [self runTestLimit:2 forwards:true cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
        XCTAssertEqual(status, ARTStatusOk);
        NSArray *messages = [result current];
        XCTAssertEqual(2, messages.count);
        XCTAssert([result hasNext]);
        ARTPresenceMessage *m0 = messages[0];
        ARTPresenceMessage *m1 = messages[1];
        
        XCTAssertEqual(m0.action, ARTPresenceMessageEnter);
        XCTAssertEqualObjects([self enter1Str], [m0 content]);
        
        XCTAssertEqualObjects([self enter2Str], [m1 content]);
        XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
        
        [result getNext:^(ARTStatus status, id<ARTPaginatedResult> result2) {
            
            NSArray *messages = [result2 current];
            XCTAssertEqual(1, messages.count);
            XCTAssertFalse([result2 hasNext]);
            ARTPresenceMessage *m0 = messages[0];
            XCTAssertEqualObjects([self updateStr], [m0 content]);
            XCTAssertEqual(m0.action, ARTPresenceMessageUpdate);
        }];
    }];
}



- (void)testLimitBackward{
    [self runTestLimit:2 forwards:false cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
        XCTAssertEqual(status, ARTStatusOk);
        NSArray *messages = [result current];
        XCTAssertEqual(2, messages.count);
        XCTAssert([result hasNext]);
        ARTPresenceMessage *m0 = messages[0];
        ARTPresenceMessage *m1 = messages[1];
        
        XCTAssertEqual(m0.action, ARTPresenceMessageUpdate);
        XCTAssertEqualObjects([self updateStr], [m0 content]);
        
        XCTAssertEqualObjects([self enter2Str], [m1 content]);
        XCTAssertEqual(m1.action, ARTPresenceMessageUpdate);
        
        [result getNext:^(ARTStatus status, id<ARTPaginatedResult> result2) {
            
            NSArray *messages = [result2 current];
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
-(void) runTestTimeForwards:(bool) forwards limit:(int) limit cb:(ARTPaginatedResultCb) cb
{
    XCTestExpectation * dummyExpectation= [self expectationWithDescription:@"dummyExpectation"];
    
    //TODO whats this for.
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        NSLog(@"WAAAAT");
        [dummyExpectation fulfill];
    }];
    NSLog(@"wtf");
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    NSLog(@"done");
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testWaitTextBackward"];
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
                        NSLog(@"odd????");
        }];
        XCTestExpectation * firstBatchExpectation= [self expectationWithDescription:@"firstBatchExpectation"];
        
        int firstBatchTotal = [self firstBatchSize];
        int secondBatchTotal = [self secondBatchSize];
        int thirdBatchTotal = [self thirdBatchSize];
        
        NSLog(@"enter");
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            NSLog(@"wtf????");
            if(cState == ARTRealtimeChannelAttached) {
                [channel publishPresenceEnter:[self enter1Str] cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    NSLog(@"enter1");
                    
                    __block int numReceived=0;
                    for(int i=0;i < firstBatchTotal; i++)
                    {
                        NSString * str = [NSString stringWithFormat:@"update%d", i];
                        [channel publishPresenceUpdate:str cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
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
        NSLog(@"waiting first batch");
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation * secondBatchExpectation= [self expectationWithDescription:@"secondBatchExpectation"];
        
        NSLog(@"done first batch");
        sleep([ARTTestUtil bigSleep]);
        long long start = [ARTTestUtil nowMilli];
        __block int numReceived=0;
        for(int i=0;i < secondBatchTotal; i++)
        {
            NSString * str = [NSString stringWithFormat:@"second_updates%d", i];
            [channel publishPresenceUpdate:str cb:^(ARTStatus status) {
                XCTAssertEqual(ARTStatusOk, status);
                sleep([ARTTestUtil smallSleep]);
                numReceived++;
                if(numReceived == secondBatchTotal) {
                    [secondBatchExpectation fulfill];
                }
            }];
        }
        NSLog(@"waiting second batch");
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation * thirdBatchExpectation= [self expectationWithDescription:@"thirdBatchExpectation"];
        
        NSLog(@"done second batch");
        sleep([ARTTestUtil bigSleep]);
        long long end = [ARTTestUtil nowMilli];
        numReceived=0;
        for(int i=0;i < thirdBatchTotal; i++)
        {
            NSString * str = [NSString stringWithFormat:@"third_updates%d", i];
            [channel publishPresenceUpdate:str cb:^(ARTStatus status) {
                sleep([ARTTestUtil smallSleep]);
                XCTAssertEqual(ARTStatusOk, status);
                numReceived++;
                if(numReceived == thirdBatchTotal) {
                    [thirdBatchExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation * historyExpecation= [self expectationWithDescription:@"historyExpecation"];
        [channel presenceHistoryWithParams:@{
                                      @"start" : [NSString stringWithFormat:@"%lld", start],
                                      @"end"   : [NSString stringWithFormat:@"%lld", end],
                                      @"limit" : [NSString stringWithFormat:@"%d", limit],
                                      @"direction" : (forwards ? @"forwards" : @"backwards")}
                                 cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                     cb(status, result);
                                     [historyExpecation fulfill];
                                 }];
         [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
    }];
}

- (void)testTimeForward {
    
    [self runTestTimeForwards:true limit:100 cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
        NSLog(@"result is %@", [result current]);
        XCTAssertEqual(status, ARTStatusOk);
        XCTAssertFalse([result hasNext]);
        NSArray * page = [result current];
        NSLog(@"page is %@", page);
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
    [self runTestTimeForwards:false limit:100 cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
        NSLog(@"result is %@", [result current]);
        XCTAssertEqual(status, ARTStatusOk);
        XCTAssertFalse([result hasNext]);
        NSArray * page = [result current];
        NSLog(@"page is %@", page);
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
    XCTFail(@"needs realtime2");
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
