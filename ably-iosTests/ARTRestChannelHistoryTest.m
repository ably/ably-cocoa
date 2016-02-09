//
//  ARTRestChannelHistoryTest.m
//  ably-ios
//
//  Created by vic on 13/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTRestChannel.h"
#import "ARTChannels.h"
#import "ARTTestUtil.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"

@interface ARTRestChannelHistoryTest : XCTestCase
{
    ARTRest *_rest;
    ARTRest *_rest2;
}
@end

@implementation ARTRestChannelHistoryTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    _rest = nil;
    _rest2 = nil;
}

- (void)testTimeBackwards {
    __block long long timeOffset = 0;
    
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest time:^(NSDate *time, NSError *error) {
            XCTAssert(!error);
            long long serverNow = [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            [e fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"firstExpectation"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest.channels get:@"testTimeBackwards"];

        int firstBatchTotal = 3;
        int secondBatchTotal = 2;
        int thirdBatchTotal = 1;
        __block long long intervalStart = 0, intervalEnd = 0;

        NSString *firstBatch = @"first_batch";
        NSString *secondBatch = @"second_batch";
        NSString *thirdBatch = @"third_batch";
        [ARTTestUtil publishRestMessages:firstBatch count:firstBatchTotal channel:(ARTChannel *)channel completion:^{
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);
            intervalStart += [ARTTestUtil nowMilli] + timeOffset;
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);

            [ARTTestUtil publishRestMessages:secondBatch count:secondBatchTotal channel:(ARTChannel *)channel completion:^{
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);
                intervalEnd += [ARTTestUtil nowMilli] + timeOffset;
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);

                [ARTTestUtil publishRestMessages:thirdBatch count:thirdBatchTotal channel:(ARTChannel *)channel completion:^{
                    ARTDataQuery *query = [[ARTDataQuery alloc] init];
                    query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart/1000];
                    query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd/1000];
                    query.direction = ARTQueryDirectionBackwards;

                    [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray *page = [result items];
                        XCTAssertTrue(page != nil);
                        XCTAssertEqual([page count], secondBatchTotal);
                        for (int i=0; i < [page count]; i++) {
                            NSString * pattern = [secondBatch stringByAppendingString:@"%d"];
                            NSString * goalStr = [NSString stringWithFormat:pattern, secondBatchTotal -1 -i];
                            ARTMessage * m = [page objectAtIndex:i];
                            XCTAssertEqualObjects(goalStr, [m data]);
                        }
                        [firstExpectation fulfill];
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
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest time:^(NSDate *time, NSError *error) {
            XCTAssert(!error);
            long long serverNow = [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            [e fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"getTime"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"test_history_time_forwards"];

        int firstBatchTotal = 2;
        int secondBatchTotal = 5;
        int thirdBatchTotal = 3;
        __block long long intervalStart = 0, intervalEnd = 0;

        NSString *firstBatch = @"first_batch";
        NSString *secondBatch = @"second_batch";
        NSString *thirdBatch =@"third_batch";

        [ARTTestUtil publishRestMessages:firstBatch count:firstBatchTotal channel:channel completion:^{
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);
            intervalStart += [ARTTestUtil nowMilli] + timeOffset;
            sleep([ARTTestUtil bigSleep]);
            sleep([ARTTestUtil bigSleep]);

            [ARTTestUtil publishRestMessages:secondBatch count:secondBatchTotal channel:channel completion:^{
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);
                intervalEnd += [ARTTestUtil nowMilli] + timeOffset;
                sleep([ARTTestUtil bigSleep]);
                sleep([ARTTestUtil bigSleep]);

                [ARTTestUtil publishRestMessages:thirdBatch count:thirdBatchTotal channel:channel completion:^{
                    ARTDataQuery *query = [[ARTDataQuery alloc] init];
                    query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart/1000];
                    query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd/1000];
                    query.direction = ARTQueryDirectionForwards;

                    [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray *page = [result items];
                        XCTAssertTrue(page != nil);
                        XCTAssertEqual([page count], secondBatchTotal);
                        for (int i=0; i < [page count]; i++)
                        {
                            NSString * pattern = [secondBatch stringByAppendingString:@"%d"];
                            NSString * goalStr = [NSString stringWithFormat:pattern, i];
                            ARTMessage * m = [page objectAtIndex:i];
                            XCTAssertEqualObjects(goalStr, [m data]);
                        }
                        [firstExpectation fulfill];
                    } error:nil];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryForwardPagination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_second_batch"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testHistoryForwardPagination"];
        
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel completion:^{
            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.limit = 2;
            query.direction = ARTQueryDirectionBackwards;

            [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                XCTAssert(!error);
                XCTAssertTrue([result hasNext]);
                NSArray *page = [result items];
                XCTAssertEqual([page count], 2);
                ARTMessage *firstMessage = [page objectAtIndex:0];
                ARTMessage *secondMessage =[page objectAtIndex:1];
                // FIXME: doesn't respect the order
                //XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                //XCTAssertEqualObjects(@"testString1", [secondMessage data]);

                [result next:^(ARTPaginatedResult *result2, NSError *error) {
                    XCTAssert(!error);
                    NSArray * page = [result2 items];
                    XCTAssertEqual([page count], 2);
                    ARTMessage * firstMessage = [page objectAtIndex:0];
                    ARTMessage * secondMessage =[page objectAtIndex:1];
                    //XCTAssertEqualObjects(@"testString2", [firstMessage data]);
                    //XCTAssertEqualObjects(@"testString3", [secondMessage data]);

                    [result2 next:^(ARTPaginatedResult *result3, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result3 hasNext]);
                        NSArray * page = [result3 items];
                        XCTAssertEqual([page count], 1);
                        ARTMessage * firstMessage = [page objectAtIndex:0];
                        //XCTAssertEqualObjects(@"testString4", [firstMessage data]);

                        [result3 first:^(ARTPaginatedResult *result4, NSError *error) {
                            XCTAssert(!error);
                            XCTAssertTrue([result4 hasNext]);
                            NSArray * page = [result4 items];
                            XCTAssertEqual([page count], 2);
                            ARTMessage * firstMessage = [page objectAtIndex:0];
                            ARTMessage * secondMessage =[page objectAtIndex:1];
                            //XCTAssertEqualObjects(@"testString0", [firstMessage data]);
                            //XCTAssertEqualObjects(@"testString1", [secondMessage data]);
                            [firstExpectation fulfill];
                        }];
                    }];
                }];
            } error:nil];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryBackwardPagination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"e"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_second_batch"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testHistoryBackwardPagination"];

        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel completion:^{
            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.limit = 2;
            query.direction = ARTQueryDirectionBackwards;

            [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                XCTAssert(!error);
                XCTAssertTrue([result hasNext]);
                NSArray * page = [result items];
                XCTAssertEqual([page count], 2);
                ARTMessage * firstMessage = [page objectAtIndex:0];
                ARTMessage * secondMessage =[page objectAtIndex:1];
                XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                XCTAssertEqualObjects(@"testString3", [secondMessage data]);

                [result next:^(ARTPaginatedResult *result2, NSError *error) {
                    XCTAssert(!error);
                    NSArray * page = [result2 items];
                    XCTAssertEqual([page count], 2);
                    ARTMessage * firstMessage = [page objectAtIndex:0];
                    ARTMessage * secondMessage =[page objectAtIndex:1];

                    XCTAssertEqualObjects(@"testString2", [firstMessage data]);
                    XCTAssertEqualObjects(@"testString1", [secondMessage data]);

                    [result2 next:^(ARTPaginatedResult *result3, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result3 hasNext]);
                        NSArray * page = [result3 items];
                        XCTAssertEqual([page count], 1);
                        ARTMessage * firstMessage = [page objectAtIndex:0];
                        XCTAssertEqualObjects(@"testString0", [firstMessage data]);

                        [result3 first:^(ARTPaginatedResult *result4, NSError *error) {
                            XCTAssert(!error);
                            XCTAssertTrue([result4 hasNext]);
                            NSArray * page = [result4 items];
                            XCTAssertEqual([page count], 2);
                            ARTMessage * firstMessage = [page objectAtIndex:0];
                            ARTMessage * secondMessage =[page objectAtIndex:1];
                            XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                            XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                            [firstExpectation fulfill];
                        }];
                    }];
                }];
            } error:nil];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryBackwardDefault {
    XCTestExpectation *expectation = [self expectationWithDescription:@"e"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_second_batch"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testHistoryBackwardDefault"];

        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel completion:^{
            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.limit = 2;

            [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                XCTAssert(!error);
                XCTAssertTrue([result hasNext]);
                NSArray * page = [result items];
                XCTAssertEqual([page count], 2);
                ARTMessage * firstMessage = [page objectAtIndex:0];
                ARTMessage * secondMessage =[page objectAtIndex:1];
                XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                [firstExpectation fulfill];
            } error:nil];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testHistoryTwoClients {
    XCTestExpectation *expectation = [self expectationWithDescription:@"e"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    NSString *channelName = @"testHistoryTwoClients";
    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_second_batch"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTRest *rest2 = [[ARTRest alloc] initWithOptions:options];
        _rest2 = rest2;

        ARTChannel *channelOne = [rest.channels get:channelName];

        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channelOne completion:^{
            ARTChannel *channelTwo = [rest2.channels get:channelName];

            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.limit = 2;

            [channelTwo history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                XCTAssert(!error);
                XCTAssertTrue([result hasNext]);
                NSArray * page = [result items];
                XCTAssertEqual([page count], 2);
                ARTMessage * firstMessage = [page objectAtIndex:0];
                ARTMessage * secondMessage =[page objectAtIndex:1];
                XCTAssertEqualObjects(@"testString4", [firstMessage data]);
                XCTAssertEqualObjects(@"testString3", [secondMessage data]);
                [firstExpectation fulfill];
            } error:nil];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryLimit {
    XCTestExpectation *exp = [self expectationWithDescription:@"testLimit"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channelOne = [rest.channels get:@"name"];

        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 1001;

        NSError *error = nil;
        BOOL valid = [channelOne history:query callback:^(ARTPaginatedResult *result, NSError *error) {} error:&error];
        XCTAssertFalse(valid);
        XCTAssertNotNil(error);
        XCTAssert(error.code == ARTDataQueryErrorLimit);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryLimitIgnoringError {
    XCTestExpectation *exp = [self expectationWithDescription:@"testLimit"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channelOne = [rest.channels get:@"name"];

        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 1001;
        // Forcing an invalid query where the error is ignored and the result should be invalid (the request was canceled)
        BOOL requested = [channelOne history:query callback:^(ARTPaginatedResult *result, NSError *error) {} error:nil];
        XCTAssertFalse(requested);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
