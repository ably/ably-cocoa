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
    ARTRealtime * _realtime2;

}
@end


@implementation ARTRealtimeChannelHistoryTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _realtime = nil;
    _realtime2 = nil;
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
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

//only for use after calling withRealtime
- (void)withRealtime2:(void (^)(ARTRealtime *realtime))cb {
    cb(_realtime2);
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
                    NSArray *messages = [result currentItems];
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
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation1 fulfill];
                    
                }];
                [channel2 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result currentItems];
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
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString", [m0 content]);
                    XCTAssertEqualObjects(@"testString2", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testHistoryForwardPagination {
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
                 NSArray * items = [result currentItems];
                 XCTAssertEqual([items count], 2);
                 ARTMessage * firstMessage = [items objectAtIndex:0];
                 ARTMessage * secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                 [result getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                     XCTAssertEqual(status, ARTStatusOk);
                     XCTAssertTrue([result2 hasFirst]);
                     NSArray * items = [result2 currentItems];
                     XCTAssertEqual([items count], 2);
                     ARTMessage * firstMessage = [items objectAtIndex:0];
                     ARTMessage * secondMessage =[items objectAtIndex:1];
                     XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                     XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                     
                     [result2 getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                         XCTAssertEqual(status, ARTStatusOk);
                         XCTAssertTrue([result3 hasFirst]);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * items = [result3 currentItems];
                         XCTAssertEqual([items count], 1);
                         ARTMessage * firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                         [result3 getFirstPage:^(ARTStatus status, id<ARTPaginatedResult> result4) {
                             XCTAssertEqual(status, ARTStatusOk);
                             XCTAssertTrue([result4 hasFirst]);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * items = [result4 currentItems];
                             XCTAssertEqual([items count], 2);
                             ARTMessage * firstMessage = [items objectAtIndex:0];
                             ARTMessage * secondMessage =[items objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                             XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                             [expectation fulfill];
                         }];
                     }];
                 }];
             }];
        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testHistoryBackwardPagination {
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
                 NSArray * items = [result currentItems];
                 XCTAssertEqual([items count], 2);
                 ARTMessage * firstMessage = [items objectAtIndex:0];
                 ARTMessage * secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                 [result getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                     XCTAssertEqual(status, ARTStatusOk);
                     XCTAssertTrue([result2 hasFirst]);
                     NSArray * items = [result2 currentItems];
                     XCTAssertEqual([items count], 2);
                     ARTMessage * firstMessage = [items objectAtIndex:0];
                     ARTMessage * secondMessage =[items objectAtIndex:1];
                     
                     XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                     XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                     
                     [result2 getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                         XCTAssertEqual(status, ARTStatusOk);
                         XCTAssertTrue([result3 hasFirst]);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * items = [result3 currentItems];
                         XCTAssertEqual([items count], 1);
                         ARTMessage * firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                         [result3 getFirstPage:^(ARTStatus status, id<ARTPaginatedResult> result4) {
                             XCTAssertEqual(status, ARTStatusOk);
                             XCTAssertTrue([result4 hasFirst]);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * items = [result4 currentItems];
                             XCTAssertEqual([items count], 2);
                             ARTMessage * firstMessage = [items objectAtIndex:0];
                             ARTMessage * secondMessage =[items objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                             XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                             [expectation fulfill];
                         }];
                         //TODO check first link works.
                     }];
                 }];
             }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testTimeBackwards {
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    
    __block long long timeOffset= 0;

    [self withRealtime:^(ARTRealtime  *realtime) {
        [realtime time:^(ARTStatus status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
   
        }];
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testTimeBackwards"];

        int firstBatchTotal =3;
        int secondBatchTotal =2;
        int thirdBatchTotal =1;
        long long intervalStart=0, intervalEnd=0;
        NSString * firstBatch = @"first_batch";
        NSString * secondBatch = @"second_batch";
        NSString * thirdBatch =@"third_batch";
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"firstExpectation"];
          

        [ARTTestUtil publishRealtimeMessages:firstBatch count:firstBatchTotal channel:channel expectation:firstExpectation];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];

        sleep([ARTTestUtil bigSleep]);
        intervalStart  = [ARTTestUtil nowMilli] + timeOffset;
        sleep([ARTTestUtil bigSleep]);

        [ARTTestUtil publishRealtimeMessages:secondBatch count:secondBatchTotal channel:channel expectation:secondExpecation];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep([ARTTestUtil bigSleep]);
        intervalEnd = [ARTTestUtil nowMilli] +timeOffset;
        sleep([ARTTestUtil bigSleep]);


        XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];

        [ARTTestUtil publishRealtimeMessages:thirdBatch count:thirdBatchTotal channel:channel expectation:thirdExpectation];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];

        [channel historyWithParams:@{
                                     @"start" : [NSString stringWithFormat:@"%lld", intervalStart],
                                     @"end"   : [NSString stringWithFormat:@"%lld", intervalEnd],
                                     @"direction" : @"backwards"}
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(status, ARTStatusOk);
                                    XCTAssertFalse([result hasNext]);
                                    NSArray * items = [result currentItems];
                                    XCTAssertTrue(items != nil);
                                    XCTAssertEqual([items count], secondBatchTotal);
                                    for(int i=0;i < [items count]; i++)
                                    {
                                        
                                        NSString * pattern = [secondBatch stringByAppendingString:@"%d"];
                                        NSString * goalStr = [NSString stringWithFormat:pattern,secondBatchTotal -1 - i];
                                        ARTMessage * m = [items objectAtIndex:i];
                                        XCTAssertEqualObjects(goalStr, [m content]);
                                    }
                                    [fourthExpectation fulfill];
                                }];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testTimeForwards {
      XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    __block long long timeOffset= 0;
    
    [self withRealtime:^(ARTRealtime  *realtime) {
        [realtime time:^(ARTStatus status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            
        }];
        [e fulfill];
    }];

    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"test_history_time_forwards"];
        int firstBatchTotal =3;
        int secondBatchTotal =2;
        int thirdBatchTotal =1;
        long long intervalStart=0, intervalEnd=0;
        NSString * firstBatch = @"first_batch";
        NSString * secondBatch = @"second_batch";
        NSString * thirdBatch =@"third_batch";
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"firstExpectation"];
        
        
        [ARTTestUtil publishRealtimeMessages:firstBatch count:firstBatchTotal channel:channel expectation:firstExpectation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        
        sleep([ARTTestUtil bigSleep]);
        intervalStart  = [ARTTestUtil nowMilli] + timeOffset;
        sleep([ARTTestUtil bigSleep]);
        
        [ARTTestUtil publishRealtimeMessages:secondBatch count:secondBatchTotal channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep([ARTTestUtil bigSleep]);
        intervalEnd = [ARTTestUtil nowMilli] +timeOffset;
        sleep([ARTTestUtil bigSleep]);
        
        
        XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        
        [ARTTestUtil publishRealtimeMessages:thirdBatch count:thirdBatchTotal channel:channel expectation:thirdExpectation];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];
 
        [channel historyWithParams:@{
                                     @"start" : [NSString stringWithFormat:@"%lld", intervalStart],
                                     @"end"   : [NSString stringWithFormat:@"%lld", intervalEnd],
                                     @"direction" : @"forwards"}
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(status, ARTStatusOk);
                                    XCTAssertFalse([result hasNext]);
                                    NSArray * items = [result currentItems];
                                    XCTAssertTrue(items != nil);
                                    XCTAssertEqual([items count], secondBatchTotal);
                                    for(int i=0;i < [items count]; i++)
                                    {
                                        NSString * pattern = [secondBatch stringByAppendingString:@"%d"];
                                        NSString * goalStr = [NSString stringWithFormat:pattern, i];
                                        
                                        ARTMessage * m = [items objectAtIndex:i];
                                        XCTAssertEqualObjects(goalStr, [m content]);
                                    }
                                    [fourthExpectation fulfill];
                                }];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
    }];
}


- (void)testHistoryFromAttach {
    XCTestExpectation *e = [self expectationWithDescription:@"testTimeBackwards"];
    
    [self withRealtime:^(ARTRealtime  *realtime) {
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    NSString * channelName = @"test_history_time_forwards";
    [self withRealtime:^(ARTRealtime  *realtime) {
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_first_batch"];
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        
        int firstBatchTotal =3;
        //send first batch, which we won't recieve in the history request
        {
            __block int numReceived =0;
            
            for(int i=0; i < firstBatchTotal; i++) {
                
                NSString * pub = [NSString stringWithFormat:@"test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    ++numReceived;
                    if(numReceived ==firstBatchTotal) {
                        [firstExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"get_history_channel2"];
        [self withRealtime2:^(ARTRealtime  *realtime2) {
            
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel2 historyWithParams:@{
                                     @"direction" : @"backwards"}
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    XCTAssertFalse([result hasNext]);
                    NSArray * items = [result currentItems];
                    XCTAssertTrue(items != nil);
                                    //TODO realtime2 isnt friends
                                    //with realtime1. dont know why.
                    XCTAssertEqual([items count], firstBatchTotal);
                    for(int i=0;i < [items count]; i++)
                    {
                        NSString * goalStr = [NSString stringWithFormat:@"test%d",firstBatchTotal -1 - i];
                        
                        ARTMessage * m = [items objectAtIndex:i];
                        XCTAssertEqualObjects(goalStr, [m content]);
                    }
                    [secondExpecation fulfill];
            }];
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
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
