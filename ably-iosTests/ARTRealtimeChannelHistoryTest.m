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
#import "ARTChannel.h"
#import "ARTRealtimeChannel.h"
#import "ARTPaginatedResult.h"
#import "ARTDataQuery.h"
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
    if (_realtime) {
        [ARTTestUtil removeAllChannels:_realtime];
        [_realtime close];
    }
    _realtime = nil;
    if (_realtime2) {
        [ARTTestUtil removeAllChannels:_realtime2];
        [_realtime2 close];
    }
    _realtime2 = nil;
}

- (void)testHistory {
    [ARTTestUtil testRealtimeV2:self withDebug:NO callback:^(ARTRealtime *realtime, ARTRealtimeConnectionState state, XCTestExpectation *expectation) {
        _realtime = realtime;

        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"persisted:testHistory"];
            [channel publish:@"testString" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStateOk, status.state);
                [channel publish:@"testString2" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStateOk, status.state);
                    [channel history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        NSArray *messages = [result items];
                        XCTAssertEqual(2, messages.count);
                        ARTMessage *m0 = messages[0];
                        ARTMessage *m1 = messages[1];
                        XCTAssertEqualObjects(@"testString2", [m0 data]);
                        XCTAssertEqualObjects(@"testString", [m1 data]);

                        [expectation fulfill];
                    } error:nil];
                }];
            }];
        }        
    }];
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
                if(status.state != ARTStateOk) {
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
        ARTRealtimeChannel *channel1 = [realtime.channels get:both];
        ARTRealtimeChannel *channel2 = [realtime.channels get:both];
        [channel1 publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStateOk, status.state);
            [channel2 publish:@"testString2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStateOk, status.state);
                [channel1 history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 data]);
                    XCTAssertEqualObjects(@"testString", [m1 data]);
                    [expectation1 fulfill];
                    
                } error:nil];
                [channel2 history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 data]);
                    XCTAssertEqualObjects(@"testString", [m1 data]);
                    [expectation2 fulfill];
                } error:nil];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testHistoryForward {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForward"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStateOk, status.state);
            [channel publish:@"testString2" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStateOk, status.state);
                ARTDataQuery* query = [[ARTDataQuery alloc] init];
                query.direction = ARTQueryDirectionForwards;
                [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString", [m0 data]);
                    XCTAssertEqualObjects(@"testString2", [m1 data]);
                    
                    [expectation fulfill];
                } error:nil];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testHistoryForwardPagination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"realHistChan"];
        
        [self publishTestStrings:channel count:5 prefix:@"testString" cb:^(ARTStatus *status){
            XCTAssertEqual(ARTStateOk, status.state);

            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.limit = 2;
            query.direction = ARTQueryDirectionForwards;
            
            [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                 XCTAssert(!error);
                 XCTAssertTrue([result hasNext]);
                 NSArray * items = [result items];
                 XCTAssertEqual([items count], 2);
                 ARTMessage * firstMessage = [items objectAtIndex:0];
                 ARTMessage * secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                 XCTAssertEqualObjects(@"testString1", [secondMessage data]);
                 [result next:^(ARTPaginatedResult *result2, NSError *error) {
                     XCTAssert(!error);
                     NSArray * items = [result2 items];
                     XCTAssertEqual([items count], 2);
                     ARTMessage * firstMessage = [items objectAtIndex:0];
                     ARTMessage * secondMessage =[items objectAtIndex:1];
                     XCTAssertEqualObjects(@"testString2", [firstMessage data]);
                     XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                     
                     [result2 next:^(ARTPaginatedResult *result3, NSError *error) {
                         XCTAssert(!error);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * items = [result3 items];
                         XCTAssertEqual([items count], 1);
                         ARTMessage * firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                         [result3 first:^(ARTPaginatedResult *result4, NSError *error) {
                             XCTAssertEqual(ARTStateOk, status.state);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * items = [result4 items];
                             XCTAssertEqual([items count], 2);
                             ARTMessage * firstMessage = [items objectAtIndex:0];
                             ARTMessage * secondMessage =[items objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                             XCTAssertEqualObjects(@"testString1", [secondMessage data]);
                             [expectation fulfill];
                         }];
                     }];
                 }];
             } error:nil];
        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testHistoryBackwardPagination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardagination"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"histRealBackChan"];
        [self publishTestStrings:channel count:5 prefix:@"testString" cb:^(ARTStatus *status){
            XCTAssertEqual(ARTStateOk, status.state);

            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.limit = 2;
            query.direction = ARTQueryDirectionBackwards;

            [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                 XCTAssert(!error);
                 XCTAssertTrue([result hasNext]);
                 NSArray * items = [result items];
                 XCTAssertEqual([items count], 2);
                 ARTMessage * firstMessage = [items objectAtIndex:0];
                 ARTMessage * secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                 XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                 [result next:^(ARTPaginatedResult *result2, NSError *error) {
                     XCTAssert(!error);
                     NSArray * items = [result2 items];
                     XCTAssertEqual([items count], 2);
                     ARTMessage * firstMessage = [items objectAtIndex:0];
                     ARTMessage * secondMessage =[items objectAtIndex:1];
                     
                     XCTAssertEqualObjects(@"testString2", [firstMessage data]);
                     XCTAssertEqualObjects(@"testString1", [secondMessage data]);
                     
                     [result2 next:^(ARTPaginatedResult *result3, NSError *error) {
                         XCTAssert(!error);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray * items = [result3 items];
                         XCTAssertEqual([items count], 1);
                         ARTMessage * firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                         [result3 first:^(ARTPaginatedResult *result4, NSError *error) {
                             XCTAssertEqual(ARTStateOk, status.state);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray * items = [result4 items];
                             XCTAssertEqual([items count], 2);
                             ARTMessage * firstMessage = [items objectAtIndex:0];
                             ARTMessage * secondMessage =[items objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                             XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                             [result2 first:^(ARTPaginatedResult *result, NSError *error) {
                                 XCTAssertEqual(ARTStateOk, status.state);
                                 XCTAssertTrue([result hasNext]);
                                 NSArray * items = [result items];
                                 XCTAssertEqual([items count], 2);
                                 ARTMessage * firstMessage = [items objectAtIndex:0];
                                 ARTMessage * secondMessage =[items objectAtIndex:1];
                                 XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                                 XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                                [expectation fulfill];
                             }];
                         }];
                     }];
                 }];
             } error:nil];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testTimeBackwards {
    __block long long timeOffset= 0;

    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime time:^(NSDate *time, NSError *error) {
            XCTAssert(!error);
            long long serverNow = [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            [e fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    [_realtime close];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"firstExpectation"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"testTimeBackwards"];

        int firstBatchTotal = 3;
        int secondBatchTotal = 2;
        int thirdBatchTotal = 1;
        __block long long intervalStart = 0, intervalEnd = 0;

        NSString *firstBatch = @"first_batch";
        NSString *secondBatch = @"second_batch";
        NSString *thirdBatch = @"third_batch";

        [ARTTestUtil publishRealtimeMessages:firstBatch count:firstBatchTotal channel:channel completion:^{
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);
            intervalStart += [ARTTestUtil nowMilli] + timeOffset;
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);

            [ARTTestUtil publishRealtimeMessages:secondBatch count:secondBatchTotal channel:channel completion:^{
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);
                intervalEnd += [ARTTestUtil nowMilli] + timeOffset;
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);

                [ARTTestUtil publishRealtimeMessages:thirdBatch count:thirdBatchTotal channel:channel completion:^{
                    ARTDataQuery *query = [[ARTDataQuery alloc] init];
                    query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart/1000];
                    query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd/1000];
                    query.direction = ARTQueryDirectionBackwards;

                    [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray *items = [result items];
                        XCTAssertTrue(items != nil);
                        XCTAssertEqual([items count], secondBatchTotal);
                        for(int i=0; i < [items count]; i++) {
                            NSString *pattern = [secondBatch stringByAppendingString:@"%d"];
                            NSString *goalStr = [NSString stringWithFormat:pattern, secondBatchTotal -1 - i];
                            ARTMessage *m = [items objectAtIndex:i];
                            XCTAssertEqualObjects(goalStr, [m data]);
                        }
                        [expectation fulfill];
                    } error:nil];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testTimeForwards {
    __block long long timeOffset = 0;

    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime time:^(NSDate *time, NSError *error) {
            XCTAssert(!error);
            long long serverNow = [time timeIntervalSince1970]*1000;
            long long appNow = [ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;            
            [e fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    [_realtime close];

    XCTestExpectation *expectation = [self expectationWithDescription:@"firstExpectation"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"test_history_time_forwards"];

        int firstBatchTotal = 3;
        int secondBatchTotal = 2;
        int thirdBatchTotal = 1;
        __block long long intervalStart = 0, intervalEnd = 0;

        NSString *firstBatch = @"first_batch";
        NSString *secondBatch = @"second_batch";
        NSString *thirdBatch =@"third_batch";

        [ARTTestUtil publishRealtimeMessages:firstBatch count:firstBatchTotal channel:channel completion:^{
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);
            intervalStart += [ARTTestUtil nowMilli] + timeOffset;
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);

            [ARTTestUtil publishRealtimeMessages:secondBatch count:secondBatchTotal channel:channel completion:^{
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);
                intervalEnd += [ARTTestUtil nowMilli] + timeOffset;
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);

                [ARTTestUtil publishRealtimeMessages:thirdBatch count:thirdBatchTotal channel:channel completion:^{
                    ARTDataQuery *query = [[ARTDataQuery alloc] init];
                    query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart/1000];
                    query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd/1000];
                    query.direction = ARTQueryDirectionForwards;

                    [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray * items = [result items];
                        XCTAssertTrue(items != nil);
                        XCTAssertEqual([items count], secondBatchTotal);
                        for (int i=0; i < [items count]; i++) {
                            NSString * pattern = [secondBatch stringByAppendingString:@"%d"];
                            NSString * goalStr = [NSString stringWithFormat:pattern, i];

                            ARTMessage * m = [items objectAtIndex:i];
                            XCTAssertEqualObjects(goalStr, [m data]);
                        }
                        [expectation fulfill];
                    } error:nil];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryFromAttach {
    XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    NSString *channelName = @"test_history_time_forwards";
    XCTestExpectation *expecation = [self expectationWithDescription:@"send_first_batch"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRealtime * realtime =[[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;

        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        
        int firstBatchTotal =3;
        //send first batch, which we won't recieve in the history request
        __block int numReceived =0;

        for(int i=0; i < firstBatchTotal; i++) {
            NSString *pub = [NSString stringWithFormat:@"test%d", i];
            sleep([ARTTestUtil smallSleep]);
            [channel publish:pub cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStateOk, status.state);
                ++numReceived;
                if (numReceived == firstBatchTotal) {
                    ARTRealtime *realtime2 =[[ARTRealtime alloc] initWithOptions:options];
                    _realtime2 = realtime2;
                    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

                    ARTDataQuery *query = [[ARTDataQuery alloc] init];
                    query.direction = ARTQueryDirectionBackwards;

                    [channel2 history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray * items = [result items];
                        XCTAssertTrue(items != nil);
                        XCTAssertEqual([items count], firstBatchTotal);
                        for(int i=0;i < [items count]; i++) {
                            NSString * goalStr = [NSString stringWithFormat:@"test%d",firstBatchTotal -1 - i];
                            ARTMessage * m = [items objectAtIndex:i];
                            XCTAssertEqualObjects(goalStr, [m data]);
                        }
                        [expecation fulfill];
                    } error:nil];
                }
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
