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
#import "ARTChannel.h"
#import "ARTChannelCollection.h"
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

-(void) testTimeBackwards {
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    __block long long timeOffset= 0;
    
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
    
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testTimeBackwards"];

        int firstBatchTotal =3;
        int secondBatchTotal =2;
        int thirdBatchTotal =1;
        long long intervalStart=0, intervalEnd=0;

        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"firstExpectation"];
        
        NSString *firstBatch = @"first_batch";
        NSString *secondBatch = @"second_batch";
        NSString *thirdBatch = @"third_batch";
        [ARTTestUtil publishRestMessages:firstBatch count:firstBatchTotal channel:channel expectation:firstExpectation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];

        // FIXME: WTH?!
        sleep([ARTTestUtil bigSleep]);
        intervalStart = [ARTTestUtil nowMilli] + timeOffset;
        sleep([ARTTestUtil bigSleep]);
        
        [ARTTestUtil publishRestMessages:secondBatch count:secondBatchTotal channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep([ARTTestUtil bigSleep]);
        intervalEnd = [ARTTestUtil nowMilli] + timeOffset;
        sleep([ARTTestUtil bigSleep]);
        
        
        XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        
        [ARTTestUtil publishRestMessages:thirdBatch count:thirdBatchTotal channel:channel expectation:thirdExpectation];
        
        XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];


        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart];
        query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd];
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
                XCTAssertEqualObjects(goalStr, [m content]);
            }
            [fourthExpectation fulfill];
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testTimeForwards
{
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    __block long long timeOffset= 0;
    
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
    
   [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"test_history_time_forwards"];
        int firstBatchTotal =2;
        int secondBatchTotal =5;
        int thirdBatchTotal = 3;
        long long intervalStart=0, intervalEnd=0;
        XCTestExpectation *firstExpectation = [self expectationWithDescription:@"firstExpectation"];

        NSString * firstBatch = @"first_batch";
        NSString * secondBatch = @"second_batch";
        NSString * thirdBatch =@"third_batch";
        [ARTTestUtil publishRestMessages:firstBatch count:firstBatchTotal channel:channel expectation:firstExpectation];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

          XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];

        sleep([ARTTestUtil bigSleep]);
        intervalStart  = [ARTTestUtil nowMilli] + timeOffset;
        sleep([ARTTestUtil bigSleep]);

        [ARTTestUtil publishRestMessages:secondBatch count:secondBatchTotal channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep([ARTTestUtil bigSleep]);
        intervalEnd = [ARTTestUtil nowMilli] +timeOffset;
        sleep([ARTTestUtil bigSleep]);
        
        
        XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        
        [ARTTestUtil publishRestMessages:thirdBatch count:thirdBatchTotal channel:channel expectation:thirdExpectation];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];


       XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];

       ARTDataQuery *query = [[ARTDataQuery alloc] init];
       query.start = [NSDate dateWithTimeIntervalSince1970:intervalStart];
       query.end = [NSDate dateWithTimeIntervalSince1970:intervalEnd];
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
               XCTAssertEqualObjects(goalStr, [m content]);
           }
           [fourthExpectation fulfill];
       }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
    }];
}

-(void) testHistoryForwardPagination
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
     [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testHistoryForwardPagination"];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];


        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 2;
        query.direction = ARTQueryDirectionBackwards;

        [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            XCTAssertTrue([result hasFirst]);
            XCTAssertTrue([result hasNext]);
            NSArray * page = [result items];
            XCTAssertEqual([page count], 2);
            ARTMessage * firstMessage = [page objectAtIndex:0];
            ARTMessage * secondMessage =[page objectAtIndex:1];
            XCTAssertEqualObjects(@"testString0", [firstMessage content]);
            XCTAssertEqualObjects(@"testString1", [secondMessage content]);

            [result next:^(ARTPaginatedResult *result2, NSError *error) {
                XCTAssert(!error);
                XCTAssertTrue([result2 hasFirst]);
                NSArray * page = [result2 items];
                XCTAssertEqual([page count], 2);
                ARTMessage * firstMessage = [page objectAtIndex:0];
                ARTMessage * secondMessage =[page objectAtIndex:1];
                XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                XCTAssertEqualObjects(@"testString3", [secondMessage content]);

                [result2 next:^(ARTPaginatedResult *result3, NSError *error) {
                    XCTAssert(!error);
                    XCTAssertTrue([result3 hasFirst]);
                    XCTAssertFalse([result3 hasNext]);
                    NSArray * page = [result3 items];
                    XCTAssertEqual([page count], 1);
                    ARTMessage * firstMessage = [page objectAtIndex:0];
                    XCTAssertEqualObjects(@"testString4", [firstMessage content]);

                    [result3 first:^(ARTPaginatedResult *result4, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertTrue([result4 hasFirst]);
                        XCTAssertTrue([result4 hasNext]);
                        NSArray * page = [result4 items];
                        XCTAssertEqual([page count], 2);
                        ARTMessage * firstMessage = [page objectAtIndex:0];
                        ARTMessage * secondMessage =[page objectAtIndex:1];
                        XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                        XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                        [expectation fulfill];
                    }];
                }];
            }];
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}


-(void) testHistoryBackwardPagination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"e"];
     [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testHistoryBackwardPagination"];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];


        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 2;
        query.direction = ARTQueryDirectionBackwards;

        [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            XCTAssertTrue([result hasFirst]);
            XCTAssertTrue([result hasNext]);
            NSArray * page = [result items];
            XCTAssertEqual([page count], 2);
            ARTMessage * firstMessage = [page objectAtIndex:0];
            ARTMessage * secondMessage =[page objectAtIndex:1];
            XCTAssertEqualObjects(@"testString4", [firstMessage content]);
            XCTAssertEqualObjects(@"testString3", [secondMessage content]);

            [result next:^(ARTPaginatedResult *result2, NSError *error) {
                XCTAssert(!error);
                XCTAssertTrue([result2 hasFirst]);
                NSArray * page = [result2 items];
                XCTAssertEqual([page count], 2);
                ARTMessage * firstMessage = [page objectAtIndex:0];
                ARTMessage * secondMessage =[page objectAtIndex:1];

                XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                XCTAssertEqualObjects(@"testString1", [secondMessage content]);

                [result2 next:^(ARTPaginatedResult *result3, NSError *error) {
                    XCTAssert(!error);
                    XCTAssertTrue([result3 hasFirst]);
                    XCTAssertFalse([result3 hasNext]);
                    NSArray * page = [result3 items];
                    XCTAssertEqual([page count], 1);
                    ARTMessage * firstMessage = [page objectAtIndex:0];
                    XCTAssertEqualObjects(@"testString0", [firstMessage content]);

                    [result3 first:^(ARTPaginatedResult *result4, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertTrue([result4 hasFirst]);
                        XCTAssertTrue([result4 hasNext]);
                        NSArray * page = [result4 items];
                        XCTAssertEqual([page count], 2);
                        ARTMessage * firstMessage = [page objectAtIndex:0];
                        ARTMessage * secondMessage =[page objectAtIndex:1];
                        XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                        XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                        [expectation fulfill];
                    }];
                }];
            }];
        }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testHistoryBackwardDefault {
    XCTestExpectation *expectation = [self expectationWithDescription:@"e"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testHistoryBackwardDefault"];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardDefault"];


        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 2;

        [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            XCTAssertTrue([result hasFirst]);
            XCTAssertTrue([result hasNext]);
            NSArray * page = [result items];
            XCTAssertEqual([page count], 2);
            ARTMessage * firstMessage = [page objectAtIndex:0];
            ARTMessage * secondMessage =[page objectAtIndex:1];
            XCTAssertEqualObjects(@"testString4", [firstMessage content]);
            XCTAssertEqualObjects(@"testString3", [secondMessage content]);
            [expectation fulfill];
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testHistoryTwoClients {
    XCTestExpectation *expectation = [self expectationWithDescription:@"e"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [expectation fulfill];
    }];
    
    NSString * channelName = @"testHistoryTwoClients";
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTRest * rest2 = [[ARTRest alloc] initWithOptions:options];
        _rest2 = rest2;
        ARTChannel *channelOne = [rest.channels get:channelName];
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channelOne expectation:secondExpecation];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        ARTChannel *channelTwo = [rest2.channels get:channelName];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryTwoClients"];

        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 2;

        [channelTwo history:query callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            XCTAssertTrue([result hasFirst]);
            XCTAssertTrue([result hasNext]);
            NSArray * page = [result items];
            XCTAssertEqual([page count], 2);
            ARTMessage * firstMessage = [page objectAtIndex:0];
            ARTMessage * secondMessage =[page objectAtIndex:1];
            XCTAssertEqualObjects(@"testString4", [firstMessage content]);
            XCTAssertEqualObjects(@"testString3", [secondMessage content]);
            [expectation fulfill];
        }];

        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

-(void) testHistoryLimit {
    XCTestExpectation *exp = [self expectationWithDescription:@"testLimit"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channelOne = [rest.channels get:@"name"];

        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 1001;

        XCTAssertThrows([channelOne history:query callback:^(ARTPaginatedResult *result, NSError *error) {}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
