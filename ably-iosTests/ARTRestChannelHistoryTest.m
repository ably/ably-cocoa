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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTTestUtil.h"
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
        [rest time:^(ARTStatus *status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status.status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
        }];
        [e fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest channel:@"testTimeBackwards"];

        int firstBatchTotal =3;
        int secondBatchTotal =2;
        int thirdBatchTotal =1;
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
        
        XCTestExpectation *fourthExpectation = [self expectationWithDescription:@"send_fourth_batch"];
        [channel historyWithParams:@{
                                     @"start" : [NSString stringWithFormat:@"%lld", intervalStart],
                                     @"end"   : [NSString stringWithFormat:@"%lld", intervalEnd],
                                     @"direction" : @"backwards"}
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(ARTStatusOk, status.status);
                                    XCTAssertFalse([result hasNext]);
                                    NSArray * page = [result currentItems];
                                    XCTAssertTrue(page != nil);
                                    XCTAssertEqual([page count], secondBatchTotal);
                                    for(int i=0;i < [page count]; i++)
                                    {
                                        
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
       [rest time:^(ARTStatus *status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status.status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
       }];
       [e fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
   [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest channel:@"test_history_time_forwards"];
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
        [channel historyWithParams:@{
                                     @"start" : [NSString stringWithFormat:@"%lld", intervalStart],
                                     @"end"   : [NSString stringWithFormat:@"%lld", intervalEnd],
                                     @"direction" : @"forwards"}
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(ARTStatusOk, status.status);
                                    XCTAssertFalse([result hasNext]);
                                    NSArray * page = [result currentItems];
                                    XCTAssertTrue(page != nil);
                                    XCTAssertEqual([page count], secondBatchTotal);
                                    for(int i=0;i < [page count]; i++)
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
        ARTRestChannel *channel = [rest channel:@"testHistoryForwardPagination"];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
        
        [channel historyWithParams:@{@"limit" : @"2",
                                     @"direction" : @"forwards"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(ARTStatusOk, status.status);
             XCTAssertTrue([result hasFirst]);
             XCTAssertTrue([result hasNext]);
             NSArray * page = [result currentItems];
             XCTAssertEqual([page count], 2);
             ARTMessage * firstMessage = [page objectAtIndex:0];
             ARTMessage * secondMessage =[page objectAtIndex:1];
             XCTAssertEqualObjects(@"testString0", [firstMessage content]);
             XCTAssertEqualObjects(@"testString1", [secondMessage content]);
             [result next:^(ARTStatus *status, id<ARTPaginatedResult> result2) {
                 XCTAssertEqual(ARTStatusOk, status.status);
                 XCTAssertTrue([result2 hasFirst]);
                 NSArray * page = [result2 currentItems];
                 XCTAssertEqual([page count], 2);
                 ARTMessage * firstMessage = [page objectAtIndex:0];
                 ARTMessage * secondMessage =[page objectAtIndex:1];
                 XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString3", [secondMessage content]);
                 
                 [result2 next:^(ARTStatus *status, id<ARTPaginatedResult> result3) {
                     XCTAssertEqual(ARTStatusOk, status.status);
                     XCTAssertTrue([result3 hasFirst]);
                     XCTAssertFalse([result3 hasNext]);
                     NSArray * page = [result3 currentItems];
                     XCTAssertEqual([page count], 1);
                     ARTMessage * firstMessage = [page objectAtIndex:0];
                     XCTAssertEqualObjects(@"testString4", [firstMessage content]);
                     [result3 first:^(ARTStatus *status, id<ARTPaginatedResult> result4) {
                         XCTAssertEqual(ARTStatusOk, status.status);
                         XCTAssertTrue([result4 hasFirst]);
                         XCTAssertTrue([result4 hasNext]);
                         NSArray * page = [result4 currentItems];
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
        ARTRestChannel *channel = [rest channel:@"testHistoryBackwardPagination"];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
        [channel historyWithParams:@{@"limit" : @"2",
                                 @"direction" : @"backwards"}
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(ARTStatusOk, status.status);
             XCTAssertTrue([result hasFirst]);
             XCTAssertTrue([result hasNext]);
             NSArray * page = [result currentItems];
             XCTAssertEqual([page count], 2);
             ARTMessage * firstMessage = [page objectAtIndex:0];
             ARTMessage * secondMessage =[page objectAtIndex:1];
             XCTAssertEqualObjects(@"testString4", [firstMessage content]);
             XCTAssertEqualObjects(@"testString3", [secondMessage content]);
             [result next:^(ARTStatus *status, id<ARTPaginatedResult> result2) {
                 XCTAssertEqual(ARTStatusOk, status.status);
                 XCTAssertTrue([result2 hasFirst]);
                 NSArray * page = [result2 currentItems];
                 XCTAssertEqual([page count], 2);
                 ARTMessage * firstMessage = [page objectAtIndex:0];
                 ARTMessage * secondMessage =[page objectAtIndex:1];
                
                 XCTAssertEqualObjects(@"testString2", [firstMessage content]);
                 XCTAssertEqualObjects(@"testString1", [secondMessage content]);
                 
                 [result2 next:^(ARTStatus *status, id<ARTPaginatedResult> result3) {
                     XCTAssertEqual(ARTStatusOk, status.status);
                     XCTAssertTrue([result3 hasFirst]);
                     XCTAssertFalse([result3 hasNext]);
                     NSArray * page = [result3 currentItems];
                     XCTAssertEqual([page count], 1);
                     ARTMessage * firstMessage = [page objectAtIndex:0];
                     XCTAssertEqualObjects(@"testString0", [firstMessage content]);
                     [result3 first:^(ARTStatus *status, id<ARTPaginatedResult> result4) {
                         XCTAssertEqual(ARTStatusOk, status.status);
                         XCTAssertTrue([result4 hasFirst]);
                         XCTAssertTrue([result4 hasNext]);
                         NSArray * page = [result4 currentItems];
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
        ARTRestChannel *channel = [rest channel:@"testHistoryBackwardDefault"];
        
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channel expectation:secondExpecation];
        
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardDefault"];
        [channel historyWithParams:@{@"limit" : @"2",}
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(ARTStatusOk, status.status);
                                    XCTAssertTrue([result hasFirst]);
                                    XCTAssertTrue([result hasNext]);
                                    NSArray * page = [result currentItems];
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
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTRest * rest2 = [[ARTRest alloc] initWithOptions:options];
        _rest2 = rest2;
        ARTRestChannel *channelOne = [rest channel:channelName];
        XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        [ARTTestUtil publishRestMessages:@"testString" count:5 channel:channelOne expectation:secondExpecation];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        ARTRestChannel *channelTwo = [rest2 channel:channelName];
        XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryTwoClients"];
        [channelTwo historyWithParams:@{@"limit" : @"2",}
                                cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(ARTStatusOk, status.status);
                                    XCTAssertTrue([result hasFirst]);
                                    XCTAssertTrue([result hasNext]);
                                    NSArray * page = [result currentItems];
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
        ARTRestChannel *channelOne = [rest channel:@"name"];
        XCTAssertThrows([channelOne historyWithParams:@{@"limit" : @"1001"} cb:^(ARTStatus * s, id<ARTPaginatedResult> r){}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
