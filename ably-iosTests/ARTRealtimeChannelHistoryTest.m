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
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRealtime.h"
#import "ARTTestUtil.h"

@interface ARTRealtimeChannelHistoryTest : XCTestCase {
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end


@implementation ARTRealtimeChannelHistoryTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    _realtime = nil;
    _realtime2 = nil;
}

- (void)testHistory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publish:@"testString2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
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
                        cb:(void (^) (ARTStatus *status)) cb
{
    {
        __block int numReceived =0;
        __block bool done =false;
        for(int i=0; i < count; i++) {
            NSString * pub = [prefix stringByAppendingString:[NSString stringWithFormat:@"%d", i]];
            [channel publish:pub cb:^(ARTStatus *status) {
                if(status.status != ARTStatusOk) {
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
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        NSString * both = @"historyBoth";
        ARTRealtimeChannel *channel1 = [realtime channel:both];
        ARTRealtimeChannel *channel2 = [realtime channel:both];
        [channel1 publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel2 publish:@"testString2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel1 history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation1 fulfill];
                    
                }];
                [channel2 history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
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
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publish:@"testString2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel historyWithParams:@{@"direction" : @"forwards"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
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
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"realHistChan"];
        
        [self publishTestStrings:channel count:5 prefix:@"testString" cb:^(ARTStatus *status){
            XCTAssertEqual(ARTStatusOk, status.status);
            
            [channel
             historyWithParams:@{@"limit" : @"2",
                                         @"direction" : @"forwards"}
                            cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                 XCTAssertEqual(ARTStatusOk, status.status);
                 XCTAssertTrue([result hasFirst]);
                 XCTAssertTrue([result hasNext]);
                 NSArray * items = [result currentItems];
                 XCTAssertEqual([items count], 2);
                 ARTMessage * firstMessage = [items objectAtIndex:0];
                 ARTMessage * secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                 [result next:^(ARTStatus *status, id<ARTPaginatedResult> result2) {
                     XCTAssertEqual(ARTStatusOk, status.status);
                     XCTAssertTrue([result2 hasFirst]);
                     NSArray * items = [result2 currentItems];
                     XCTAssertEqual([items count], 2);
                     ARTMessage * firstMessage = [items objectAtIndex:0];
                     ARTMessage * secondMessage =[items objectAtIndex:1];
                     XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                     XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                     
                     [result2 next:^(ARTStatus *status, id<ARTPaginatedResult> result3) {
                         XCTAssertEqual(ARTStatusOk, status.status);
                         XCTAssertTrue([result3 hasFirst]);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * items = [result3 currentItems];
                         XCTAssertEqual([items count], 1);
                         ARTMessage * firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                         [result3 first:^(ARTStatus *status, id<ARTPaginatedResult> result4) {
                             XCTAssertEqual(ARTStatusOk, status.status);
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
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"histRealBackChan"];
        [self publishTestStrings:channel count:5 prefix:@"testString" cb:^(ARTStatus *status){
            XCTAssertEqual(ARTStatusOk, status.status);
                            [channel historyWithParams:@{@"limit" : @"2",
             @"direction" : @"backwards"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                 XCTAssertEqual(ARTStatusOk, status.status);
                 XCTAssertTrue([result hasFirst]);
                 XCTAssertTrue([result hasNext]);
                 NSArray * items = [result currentItems];
                 XCTAssertEqual([items count], 2);
                 ARTMessage * firstMessage = [items objectAtIndex:0];
                 ARTMessage * secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                 [result next:^(ARTStatus *status, id<ARTPaginatedResult> result2) {
                     XCTAssertEqual(ARTStatusOk, status.status);
                     XCTAssertTrue([result2 hasFirst]);
                     NSArray * items = [result2 currentItems];
                     XCTAssertEqual([items count], 2);
                     ARTMessage * firstMessage = [items objectAtIndex:0];
                     ARTMessage * secondMessage =[items objectAtIndex:1];
                     
                     XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                     XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                     
                     [result2 next:^(ARTStatus *status, id<ARTPaginatedResult> result3) {
                         XCTAssertEqual(ARTStatusOk, status.status);
                         XCTAssertTrue([result3 hasFirst]);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * items = [result3 currentItems];
                         XCTAssertEqual([items count], 1);
                         ARTMessage * firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                         [result3 first:^(ARTStatus *status, id<ARTPaginatedResult> result4) {
                             XCTAssertEqual(ARTStatusOk, status.status);
                             XCTAssertTrue([result4 hasFirst]);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * items = [result4 currentItems];
                             XCTAssertEqual([items count], 2);
                             ARTMessage * firstMessage = [items objectAtIndex:0];
                             ARTMessage * secondMessage =[items objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                             XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                             [result2 first:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                 XCTAssertEqual(ARTStatusOk, status.status);
                                 XCTAssertTrue([result hasFirst]);
                                 XCTAssertTrue([result hasNext]);
                                 NSArray * items = [result currentItems];
                                 XCTAssertEqual([items count], 2);
                                 ARTMessage * firstMessage = [items objectAtIndex:0];
                                 ARTMessage * secondMessage =[items objectAtIndex:1];
                                 XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                                 XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                                [expectation fulfill];
                             }];
                         }];
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

    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        [realtime time:^(ARTStatus *status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status.status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
   
        }];
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
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
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(ARTStatusOk, status.status);
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
    
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime time:^(ARTStatus *status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status.status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            
        }];
        [e fulfill];
    }];

    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
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
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(ARTStatusOk, status.status);
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
    
    XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    NSString * channelName = @"test_history_time_forwards";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTClientOptions *options) {
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_first_batch"];
        ARTRealtime * realtime =[[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;

    
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        
        int firstBatchTotal =3;
        //send first batch, which we won't recieve in the history request
        {
            __block int numReceived =0;
            
            for(int i=0; i < firstBatchTotal; i++) {
                
                NSString * pub = [NSString stringWithFormat:@"test%d", i];
                sleep([ARTTestUtil smallSleep]);
                [channel publish:pub cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    ++numReceived;
                    if(numReceived ==firstBatchTotal) {
                        [firstExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"get_history_channel2"];
        ARTRealtime * realtime2 =[[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = realtime2;
        ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
        [channel2 historyWithParams:@{
                                 @"direction" : @"backwards"}
                            cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                XCTAssertFalse([result hasNext]);
                NSArray * items = [result currentItems];
                XCTAssertTrue(items != nil);
                XCTAssertEqual([items count], firstBatchTotal);
                for(int i=0;i < [items count]; i++) {
                    NSString * goalStr = [NSString stringWithFormat:@"test%d",firstBatchTotal -1 - i];
                    ARTMessage * m = [items objectAtIndex:i];
                    XCTAssertEqualObjects(goalStr, [m content]);
                }
                [secondExpecation fulfill];
        }];
    
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}


//TODO find out why untilAttach doesn't work
/*
- (void)testHistoryUntilAttach {
    XCTestExpectation *exp = [self expectationWithDescription:@"testHistoryUntilAttach"];
    NSString * firstString = @"firstString";
    NSString * channelName  = @"name";
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTClientOptions *options) {
        ARTRealtime * realtime =[[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        ARTRealtime * realtime2 =[[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = realtime2;
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel publish:firstString cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
        }];
      //  ARTRealtimeChannel *channel = [realtime channel:@"untilAttach"];
        XCTAssertThrows([channel historyWithParams:@{@"until_attach" : @"true"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {}]);
        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publish:@"testString2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel historyWithParams:@{@"direction" : @"forwards", @"until_attach" : @"true"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString", [m0 content]);
                    XCTAssertEqualObjects(@"testString2", [m1 content]);
                    
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
 */

@end
