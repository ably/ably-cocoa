//
//  ARTRealtimeChannelHistoryTest.m
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

@interface ARTRealtimeChannelHistoryTest : XCTestCase
{
    ARTRealtime * _realtime;
}
@end


@implementation ARTRealtimeChannelHistoryTest

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
        _realtime = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}



- (void)testHistory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



-(void) publishTestStrings:(ARTRealtimeChannel *) channel
                     count:(int) count
                    prefix:(NSString *) prefix
                        cb:(void (^) (ARTStatus status)) cb
{
    //send first batch, which we won't recieve in the history request
    {
        __block int numReceived =0;
        __block bool done =false;
        for(int i=0; i < count; i++) {
            NSString * pub = [prefix stringByAppendingString:[NSString stringWithFormat:@"%d", i]];
            [channel publish:pub cb:^(ARTStatus status) {
                
                if(status != ARTStatusOk) {
                    
                    if(!done) {
                        done = true;
                        cb(status);
                    }
                    return;
                }
                ++numReceived;
                if(numReceived ==count) {
                    if(!done) {
                        done = true;
                        cb(status);
                        return;
                    }
                    
                }
            }];
        }
    }
}

- (void) testHistoryBothChannels {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"historyBothChanels1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"historyBothChanels2"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        NSString * both = @"historyBoth";
        ARTRealtimeChannel *channel1 = [realtime channel:both];
        ARTRealtimeChannel *channel2 = [realtime channel:both];
        [channel1 publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel2 publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel1 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation1 fulfill];
                    
                }];
                [channel2 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation2 fulfill];
                    
                    
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testHistoryForward {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForward"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel historyWithParams:@{@"direction" : @"forwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


//TODO I've merged tests here into 2.
-(void) testHistoryForwardPagination
{
    NSLog(@"TEST testHistoryForwardPagination");
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"realHistChan"];
        
        [self publishTestStrings:channel count:5 prefix:@"testString" cb:^(ARTStatus status){
            XCTAssertEqual(status, ARTStatusOk);
            
            [channel
             historyWithParams:@{@"limit" : @"2",
                                         @"direction" : @"forwards"}
                            cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                 XCTAssertEqual(status, ARTStatusOk);
                 XCTAssertTrue([result hasFirst]);
                 XCTAssertTrue([result hasNext]);
                 NSArray * page = [result current];
                 XCTAssertEqual([page count], 2);
                 ARTMessage * firstMessage = [page objectAtIndex:0];
                 ARTMessage * secondMessage =[page objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                 [result getNext:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                     XCTAssertEqual(status, ARTStatusOk);
                     XCTAssertTrue([result2 hasFirst]);
                     NSArray * page = [result2 current];
                     XCTAssertEqual([page count], 2);
                     ARTMessage * firstMessage = [page objectAtIndex:0];
                     ARTMessage * secondMessage =[page objectAtIndex:1];
                     XCTAssertEqualObjects(@"testString3", [firstMessage content]);
                     XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                     
                     [result2 getNext:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                         XCTAssertEqual(status, ARTStatusOk);
                         XCTAssertTrue([result3 hasFirst]);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * page = [result3 current];
                         XCTAssertEqual([page count], 1);
                         ARTMessage * firstMessage = [page objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                         [result3 getFirst:^(ARTStatus status, id<ARTPaginatedResult> result4) {
                             XCTAssertEqual(status, ARTStatusOk);
                             XCTAssertTrue([result4 hasFirst]);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * page = [result4 current];
                             XCTAssertEqual([page count], 2);
                             ARTMessage * firstMessage = [page objectAtIndex:0];
                             ARTMessage * secondMessage =[page objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                             XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                             [expectation fulfill];
                         }];
                     }];
                 }];
             }];
        }];
    }];
    //TODO TIMER
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//TODO ios status doc
-(void) testHistoryBackwardPagination
{
    NSLog(@"TEST testHistoryBackwardPagination");
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardagination"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"histRealBackChan"];
        [self publishTestStrings:channel count:5 prefix:@"testString" cb:^(ARTStatus status){
            XCTAssertEqual(status, ARTStatusOk);
                            [channel historyWithParams:@{@"limit" : @"2",
             @"direction" : @"backwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                 XCTAssertEqual(status, ARTStatusOk);
                 XCTAssertTrue([result hasFirst]);
                 XCTAssertTrue([result hasNext]);
                 NSArray * page = [result current];
                 XCTAssertEqual([page count], 2);
                 ARTMessage * firstMessage = [page objectAtIndex:0];
                 ARTMessage * secondMessage =[page objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                 [result getNext:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                     XCTAssertEqual(status, ARTStatusOk);
                     XCTAssertTrue([result2 hasFirst]);
                     NSArray * page = [result2 current];
                     XCTAssertEqual([page count], 2);
                     ARTMessage * firstMessage = [page objectAtIndex:0];
                     ARTMessage * secondMessage =[page objectAtIndex:1];
                     
                     XCTAssertEqualObjects(@"testString3", [firstMessage content]);
                     XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                     
                     [result2 getNext:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                         XCTAssertEqual(status, ARTStatusOk);
                         XCTAssertTrue([result3 hasFirst]);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * page = [result3 current];
                         XCTAssertEqual([page count], 1);
                         ARTMessage * firstMessage = [page objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                         [result3 getFirst:^(ARTStatus status, id<ARTPaginatedResult> result4) {
                             XCTAssertEqual(status, ARTStatusOk);
                             XCTAssertTrue([result4 hasFirst]);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * page = [result4 current];
                             XCTAssertEqual([page count], 2);
                             ARTMessage * firstMessage = [page objectAtIndex:0];
                             ARTMessage * secondMessage =[page objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                             XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                             [expectation fulfill];
                         }];
                         
                         //TODO check first link works.
                     }];
                 }];
                 
             }];
                        }];
                    }];
    /*
                }];
            }];
        }];
    }];
     */
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testTimeBackwards
{
    
    NSLog(@"TEST testTimeBackwards");
    XCTestExpectation *e = [self expectationWithDescription:@"testTimeBackwards"];
    
    [self withRealtime:^(ARTRealtime  *realtime) {
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
      [self withRealtime:^(ARTRealtime  *realtime) {
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_first_batch"];
        ARTRealtimeChannel *channel = [realtime channel:@"test_history_time_forwards"];
        
        int firstBatchTotal =3;
        int secondBatchTotal =2;
        int thirdBatchTotal =1;
        long long intervalStart=0, intervalEnd=0;
        
        //send first batch, which we won't recieve in the history request
        {
            __block int numReceived =0;
            
            for(int i=0; i < firstBatchTotal; i++) {
                
                NSString * pub = [NSString stringWithFormat:@"test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived;
                    if(numReceived ==firstBatchTotal) {
                        [firstExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        //send second batch (which we will retrieve via interval history request
        {
            
            sleep([ARTTestUtil bigSleep]);
            intervalStart  = [ARTTestUtil nowMilli];
            __block int numReceived2 =0;
            
            for(int i=0; i < secondBatchTotal; i++) {
                NSString * pub = [NSString stringWithFormat:@"second_test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived2;
                    if(numReceived2 ==secondBatchTotal) {
                        [secondExpecation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep([ARTTestUtil bigSleep]);
        intervalEnd = [ARTTestUtil nowMilli];
        XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        //send third batch, which we won't receieve in the history request
        {
            __block int numReceived3 =0;
            
            for(int i=0; i < thirdBatchTotal; i++) {
                NSLog(@"third batchb %d", i);
                NSString * pub = [NSString stringWithFormat:@"third_test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived3;
                    if(numReceived3 ==thirdBatchTotal) {
                        NSLog(@"third fulfilled backwards");
                        [thirdExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];
        
        NSLog(@"SENDINGb hsitory in time req %lld %lld", intervalStart, intervalEnd);
        [channel historyWithParams:@{
                                     @"start" : [NSString stringWithFormat:@"%lld", intervalStart],
                                     @"end"   : [NSString stringWithFormat:@"%lld", intervalEnd],
                                     @"direction" : @"backwards"}
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(status, ARTStatusOk);
                                    XCTAssertFalse([result hasNext]);
                                    NSArray * page = [result current];
                                    XCTAssertTrue(page != nil);
                                    XCTAssertEqual([page count], secondBatchTotal);
                                    for(int i=0;i < [page count]; i++)
                                    {
                                        
                                        NSString * goalStr = [NSString stringWithFormat:@"second_test%d",secondBatchTotal -1 - i];
                                        
                                        ARTMessage * m = [page objectAtIndex:i];
                                        XCTAssertEqualObjects(goalStr, [m content]);
                                    }
                                    [fourthExpectation fulfill];
                                }];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testTimeForwards
{
    
    NSLog(@"TEST TIME FORWRDS REALTIEME");
    XCTestExpectation *e = [self expectationWithDescription:@"testTimeForwards"];
    
    //TODO whats this for.
    [self withRealtime:^(ARTRealtime  *realtime) {
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRealtime:^(ARTRealtime  *realtime) {
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_first_batch"];
        ARTRealtimeChannel *channel = [realtime channel:@"test_history_time_forwards"];
        
        int firstBatchTotal =10;
        int secondBatchTotal =5;
        long long intervalStart=0, intervalEnd=0;
        
        //send first batch, which we won't recieve in the history request
        {
            
            
            __block int numReceived =0;
            
            for(int i=0; i < firstBatchTotal; i++) {
                
                NSLog(@"first batch %d", i);
                NSString * pub = [NSString stringWithFormat:@"test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived;
                    if(numReceived ==firstBatchTotal) {
                        [firstExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        //send second batch (which we will retrieve via interval history request
        {
            sleep([ARTTestUtil bigSleep]);
            intervalStart  = [ARTTestUtil nowMilli];
            __block int numReceived2 =0;
            
            for(int i=0; i < secondBatchTotal; i++) {
                NSLog(@"second batch %d", i);
                NSString * pub = [NSString stringWithFormat:@"second_test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived2;
                    if(numReceived2 ==secondBatchTotal) {
                        [secondExpecation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep([ARTTestUtil bigSleep]);
        intervalEnd = [ARTTestUtil nowMilli];
        
        XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        //send third batch, which we won't receieve in the history request
        {
            __block int numReceived3 =0;
            
            for(int i=0; i < secondBatchTotal; i++) {
                NSLog(@"third batch %d", i);
                NSString * pub = [NSString stringWithFormat:@"third_test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived3;
                    if(numReceived3 ==secondBatchTotal) {
                        NSLog(@"third fulfilled");
                        [thirdExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];
        
        NSLog(@"SENDING hsitory in time req %lld %lld", intervalStart, intervalEnd);
        [channel historyWithParams:@{
                                     @"start" : [NSString stringWithFormat:@"%lld", intervalStart],
                                     @"end"   : [NSString stringWithFormat:@"%lld", intervalEnd],
                                     @"direction" : @"forwards"}
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(status, ARTStatusOk);
                                    XCTAssertFalse([result hasNext]);
                                    NSArray * page = [result current];
                                    XCTAssertTrue(page != nil);
                                    XCTAssertEqual([page count], secondBatchTotal);
                                    for(int i=0;i < [page count]; i++)
                                    {
                                        
                                        NSString * goalStr = [NSString stringWithFormat:@"second_test%d", i];
                                        
                                        ARTMessage * m = [page objectAtIndex:i];
                                        XCTAssertEqualObjects(goalStr, [m content]);
                                    }
                                    [fourthExpectation fulfill];
                                }];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
    }];
}


- (void)testHistoryFromAttach{
    XCTFail(@"TODO write test");
}


/* msgpack not implemented yet
 
-(void)testHistoryBinary {
    XCTFail(@"TODO write test");
}
- (void)testHistoryWaitBinaryBackward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryMixedBinaryFoward {
    XCTFail(@"TODO write test");
}
-(void)testHistoryWaitBinaryForward {
    XCTFail(@"TODO write test");
}
-(void)testHistoryTypesBinary {
    XCTFail(@"TODO write test");
}
-(void)testHistoryWaitBinary {
    XCTFail(@"TODO write test");
}
 */


@end
