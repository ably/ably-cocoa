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
    ARTRealtime *_realtime;
    ARTRealtime *_realtime2;
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
        [_realtime.connection close];
    }
    _realtime = nil;
    if (_realtime2) {
        [ARTTestUtil removeAllChannels:_realtime2];
        [_realtime2.connection close];
    }
    _realtime2 = nil;
}

- (void)testHistory {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            ARTErrorInfo *errorInfo = stateChange.reason;
            if (state == ARTRealtimeFailed) {
                if (errorInfo) {
                    XCTFail(@"Realtime connection failed: %@", errorInfo);
                }
                else {
                    XCTFail(@"Realtime connection failed");
                }
                [expectation fulfill];
            }
            else {
                if (state == ARTRealtimeConnected) {
                    ARTRealtimeChannel *channel = [realtime.channels get:@"persisted:testHistory"];
                    [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel publish:nil data:@"testString2" callback:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNil(errorInfo);
                            [channel history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                                XCTAssert(!error);
                                NSArray *messages = [result items];
                                XCTAssertEqual(2, messages.count);
                                ARTMessage *m0 = messages[0];
                                ARTMessage *m1 = messages[1];
                                XCTAssertEqualObjects(@"testString2", [m0 data]);
                                XCTAssertEqualObjects(@"testString", [m1 data]);
                                [expectation fulfill];
                            }];
                        }];
                    }];
                }
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)publishTestStrings:(ARTRealtimeChannel *)channel count:(int)count prefix:(NSString *)prefix callback:(void (^)(ARTErrorInfo *errorInfo))cb {
    __block int numReceived = 0;
    __block bool done = false;

    for (int i=0; i < count; i++) {
        NSString *pub = [prefix stringByAppendingString:[NSString stringWithFormat:@"%d", i]];
        [channel publish:nil data:pub callback:^(ARTErrorInfo *errorInfo) {
            if(channel.state != ARTStateOk) {
                if(!done) {
                    done = true;
                    cb(errorInfo);
                }
                return;
            }
            ++numReceived;
            if(numReceived ==count) {
                if(!done) {
                    done = true;
                    cb(errorInfo);
                    return;
                }
                
            }
        }];
    }
}

- (void)testHistoryBothChannels {
    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:@"historyBothChanels1"];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:@"historyBothChanels2"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        NSString *both = @"historyBoth";
        ARTRealtimeChannel *channel1 = [realtime.channels get:both];
        ARTRealtimeChannel *channel2 = [realtime.channels get:both];
        [channel1 publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel2 publish:nil data:@"testString2" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [channel1 history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 data]);
                    XCTAssertEqualObjects(@"testString", [m1 data]);
                    [expectation1 fulfill];
                    
                }];
                [channel2 history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 data]);
                    XCTAssertEqualObjects(@"testString", [m1 data]);
                    [expectation2 fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryForward {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForward"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"persisted:testHistory"];
        [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel publish:nil data:@"testString2" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                ARTRealtimeHistoryQuery* query = [[ARTRealtimeHistoryQuery alloc] init];
                query.direction = ARTQueryDirectionForwards;
                [channel history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
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

- (void)testHistoryForwardPagination {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"realHistChan"];
        
        [self publishTestStrings:channel count:5 prefix:@"testString" callback:^(ARTErrorInfo *errorInfo){
            XCTAssertNil(errorInfo);

            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
            query.limit = 2;
            query.direction = ARTQueryDirectionForwards;
            
            [channel history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                 XCTAssert(!error);
                 XCTAssertTrue([result hasNext]);
                 NSArray *items = [result items];
                 XCTAssertEqual([items count], 2);
                 ARTMessage *firstMessage = [items objectAtIndex:0];
                 ARTMessage *secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                 XCTAssertEqualObjects(@"testString1", [secondMessage data]);
                 [result next:^(ARTPaginatedResult *result2, ARTErrorInfo *error) {
                     XCTAssert(!error);
                     NSArray *items = [result2 items];
                     XCTAssertEqual([items count], 2);
                     ARTMessage *firstMessage = [items objectAtIndex:0];
                     ARTMessage *secondMessage =[items objectAtIndex:1];
                     XCTAssertEqualObjects(@"testString2", [firstMessage data]);
                     XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                     
                     [result2 next:^(ARTPaginatedResult *result3, ARTErrorInfo *error) {
                         XCTAssert(!error);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray *items = [result3 items];
                         XCTAssertEqual([items count], 1);
                         ARTMessage *firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                         [result3 first:^(ARTPaginatedResult *result4, ARTErrorInfo *error) {
                             XCTAssertNil(errorInfo);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray *items = [result4 items];
                             XCTAssertEqual([items count], 2);
                             ARTMessage *firstMessage = [items objectAtIndex:0];
                             ARTMessage *secondMessage =[items objectAtIndex:1];
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

- (void)testHistoryBackwardPagination {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardagination"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"histRealBackChan"];
        [self publishTestStrings:channel count:5 prefix:@"testString" callback:^(ARTErrorInfo *errorInfo){
            XCTAssertNil(errorInfo);

            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
            query.limit = 2;
            query.direction = ARTQueryDirectionBackwards;

            [channel history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                 XCTAssert(!error);
                 XCTAssertTrue([result hasNext]);
                 NSArray *items = [result items];
                 XCTAssertEqual([items count], 2);
                 ARTMessage *firstMessage = [items objectAtIndex:0];
                 ARTMessage *secondMessage =[items objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                 XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                 [result next:^(ARTPaginatedResult *result2, ARTErrorInfo *error) {
                     XCTAssert(!error);
                     NSArray *items = [result2 items];
                     XCTAssertEqual([items count], 2);
                     ARTMessage *firstMessage = [items objectAtIndex:0];
                     ARTMessage *secondMessage =[items objectAtIndex:1];
                     
                     XCTAssertEqualObjects(@"testString2", [firstMessage data]);
                     XCTAssertEqualObjects(@"testString1", [secondMessage data]);
                     
                     [result2 next:^(ARTPaginatedResult *result3, ARTErrorInfo *error) {
                         XCTAssert(!error);
                         XCTAssertFalse([result3 hasNext]);
                         NSArray *items = [result3 items];
                         XCTAssertEqual([items count], 1);
                         ARTMessage *firstMessage = [items objectAtIndex:0];
                         XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                         [result3 first:^(ARTPaginatedResult *result4, ARTErrorInfo *error) {
                             XCTAssert(!error);
                             XCTAssertTrue([result4 hasNext]);
                             NSArray *items = [result4 items];
                             XCTAssertEqual([items count], 2);
                             ARTMessage *firstMessage = [items objectAtIndex:0];
                             ARTMessage *secondMessage =[items objectAtIndex:1];
                             XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                             XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                             [result2 first:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                                 XCTAssert(!error);
                                 XCTAssertTrue([result hasNext]);
                                 NSArray *items = [result items];
                                 XCTAssertEqual([items count], 2);
                                 ARTMessage *firstMessage = [items objectAtIndex:0];
                                 ARTMessage *secondMessage =[items objectAtIndex:1];
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
    __block long long timeOffset = 0;

    __weak XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
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

    [_realtime.connection close];
    
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"firstExpectation"];
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
            [ARTTestUtil delay:[ARTTestUtil bigSleep] block:^{
                intervalStart += [ARTTestUtil nowMilli] + timeOffset;

                [ARTTestUtil publishRealtimeMessages:secondBatch count:secondBatchTotal channel:channel completion:^{
                    [ARTTestUtil delay:[ARTTestUtil bigSleep] block:^{
                        intervalEnd += [ARTTestUtil nowMilli] + timeOffset;

                        [ARTTestUtil publishRealtimeMessages:thirdBatch count:thirdBatchTotal channel:channel completion:^{
                            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                            query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart/1000];
                            query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd/1000];
                            query.direction = ARTQueryDirectionBackwards;

                            [channel history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
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
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout]+8.0 handler:nil];
}

- (void)testTimeForwards {
    __block long long timeOffset = 0;

    __weak XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
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

    [_realtime.connection close];

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"firstExpectation"];
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
            [ARTTestUtil delay:[ARTTestUtil bigSleep] block:^{
                intervalStart += [ARTTestUtil nowMilli] + timeOffset;

                [ARTTestUtil publishRealtimeMessages:secondBatch count:secondBatchTotal channel:channel completion:^{
                    [ARTTestUtil delay:[ARTTestUtil bigSleep] block:^{
                        intervalEnd += [ARTTestUtil nowMilli] + timeOffset;

                        [ARTTestUtil publishRealtimeMessages:thirdBatch count:thirdBatchTotal channel:channel completion:^{
                            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                            query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart/1000];
                            query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd/1000];
                            query.direction = ARTQueryDirectionForwards;

                            [channel history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                                XCTAssert(!error);
                                XCTAssertFalse([result hasNext]);
                                NSArray *items = [result items];
                                XCTAssertTrue(items != nil);
                                XCTAssertEqual([items count], secondBatchTotal);
                                for (int i=0; i < [items count]; i++) {
                                    NSString *pattern = [secondBatch stringByAppendingString:@"%d"];
                                    NSString *goalStr = [NSString stringWithFormat:pattern, i];

                                    ARTMessage *m = [items objectAtIndex:i];
                                    XCTAssertEqualObjects(goalStr, [m data]);
                                }
                                [expectation fulfill];
                            } error:nil];
                        }];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout]+8.0 handler:nil];
}

- (void)testHistoryFromAttach {
    __weak XCTestExpectation *e = [self expectationWithDescription:@"waitExp"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    NSString *channelName = @"test_history_time_forwards";
    __weak XCTestExpectation *expecation = [self expectationWithDescription:@"send_first_batch"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        ARTRealtime *realtime =[[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;

        ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        
        int firstBatchTotal =3;
        //send first batch, which we won't recieve in the history request
        __block int numReceived =0;

        for (int i=0; i < firstBatchTotal; i++) {
            NSString *pub = [NSString stringWithFormat:@"test%d", i];

            [channel publish:nil data:pub callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                ++numReceived;
                if (numReceived == firstBatchTotal) {
                    ARTRealtime *realtime2 =[[ARTRealtime alloc] initWithOptions:options];
                    _realtime2 = realtime2;
                    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

                    ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                    query.direction = ARTQueryDirectionBackwards;

                    [channel2 history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray *items = [result items];
                        XCTAssertTrue(items != nil);
                        XCTAssertEqual([items count], firstBatchTotal);
                        for(int i=0;i < [items count]; i++) {
                            NSString *goalStr = [NSString stringWithFormat:@"test%d",firstBatchTotal -1 - i];
                            ARTMessage *m = [items objectAtIndex:i];
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
