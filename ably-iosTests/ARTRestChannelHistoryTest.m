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
@interface ARTRestChannelHistoryTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}
@end

@implementation ARTRestChannelHistoryTest



- (void)setUp {
    [super setUp];
    _options = [[ARTOptions alloc] init];
    _options.restHost = @"sandbox-rest.ably.io";
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTTestUtil setupApp:_options cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}
-(void) testTimeBackwards {
    
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    __block long long timeOffset= 0;
    
    [self withRest:^(ARTRest  *rest) {
        [rest time:^(ARTStatus status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
        }];
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
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
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(status, ARTStatusOk);
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
    
    [self withRest:^(ARTRest  *rest) {
        [rest time:^(ARTStatus status, NSDate *time) {
            XCTAssertEqual(ARTStatusOk, status);
            long long serverNow= [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
        }];
        [e fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
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
                                cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                    XCTAssertEqual(status, ARTStatusOk);
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

//TODO I've merged tests here into 2.
//TODO use ARTtestUtil publishmessages
-(void) testHistoryForwardPagination
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [self withRest:^(ARTRest  *rest) {
        
        //TODO migrate to my fancy publisher call
        ARTRestChannel *channel = [rest channel:@"testHistoryForwardPagination"];
        [channel publish:@"testString1" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel publish:@"testString3" cb:^(ARTStatus status) {
                    XCTAssertEqual(status, ARTStatusOk);
                    [channel publish:@"testString4" cb:^(ARTStatus status) {
                        XCTAssertEqual(status, ARTStatusOk);
                        [channel publish:@"testString5" cb:^(ARTStatus status) {
                            XCTAssertEqual(status, ARTStatusOk);
                            [channel historyWithParams:@{@"limit" : @"2",
                                                         @"direction" : @"forwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                                             XCTAssertEqual(status, ARTStatusOk);
                                                             XCTAssertTrue([result hasFirst]);
                                                             XCTAssertTrue([result hasNext]);
                                                             NSArray * page = [result currentItems];
                                                             XCTAssertEqual([page count], 2);
                                                             ARTMessage * firstMessage = [page objectAtIndex:0];
                                                             ARTMessage * secondMessage =[page objectAtIndex:1];
                                                             XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                                                             XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                                                             [result getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                                                                 XCTAssertEqual(status, ARTStatusOk);
                                                                 XCTAssertTrue([result2 hasFirst]);
                                                                 NSArray * page = [result2 currentItems];
                                                                 XCTAssertEqual([page count], 2);
                                                                 ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                 ARTMessage * secondMessage =[page objectAtIndex:1];
                                                                 XCTAssertEqualObjects(@"testString3", [firstMessage content]);
                                                                 XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                                                                 
                                                                 [result2 getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                                                                     XCTAssertEqual(status, ARTStatusOk);
                                                                     XCTAssertTrue([result3 hasFirst]);
                                                                     XCTAssertFalse([result3 hasNext]);
                                                                     NSArray * page = [result3 currentItems];
                                                                     XCTAssertEqual([page count], 1);
                                                                     ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                     XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                                                                     [result3 getFirstPage:^(ARTStatus status, id<ARTPaginatedResult> result4) {
                                                                         XCTAssertEqual(status, ARTStatusOk);
                                                                         XCTAssertTrue([result4 hasFirst]);
                                                                         XCTAssertTrue([result4 hasNext]);
                                                                         NSArray * page = [result4 currentItems];
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
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


//TODO use ARTtestUtil publishmessages
-(void) testHistoryBackwardPagination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardagination"];
    [self withRest:^(ARTRest  *rest) {
                //TODO migrate to my fancy publisher call
        ARTRestChannel *channel = [rest channel:@"testHistoryBackwardPagination"];
        [channel publish:@"testString1" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel publish:@"testString3" cb:^(ARTStatus status) {
                    XCTAssertEqual(status, ARTStatusOk);
                    [channel publish:@"testString4" cb:^(ARTStatus status) {
                        XCTAssertEqual(status, ARTStatusOk);
                        [channel publish:@"testString5" cb:^(ARTStatus status) {
                            XCTAssertEqual(status, ARTStatusOk);
                            [channel historyWithParams:@{@"limit" : @"2",
                                                         @"direction" : @"backwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                                             XCTAssertEqual(status, ARTStatusOk);
                                                             XCTAssertTrue([result hasFirst]);
                                                             XCTAssertTrue([result hasNext]);
                                                             NSArray * page = [result currentItems];
                                                             XCTAssertEqual([page count], 2);
                                                             ARTMessage * firstMessage = [page objectAtIndex:0];
                                                             ARTMessage * secondMessage =[page objectAtIndex:1];
                                                             XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                                                             XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                                                             [result getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                                                                 XCTAssertEqual(status, ARTStatusOk);
                                                                 XCTAssertTrue([result2 hasFirst]);
                                                                 NSArray * page = [result2 currentItems];
                                                                 XCTAssertEqual([page count], 2);
                                                                 ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                 ARTMessage * secondMessage =[page objectAtIndex:1];
                                                                
                                                                 XCTAssertEqualObjects(@"testString3", [firstMessage content]);
                                                                 XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                                                                 
                                                                 [result2 getNextPage:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                                                                     XCTAssertEqual(status, ARTStatusOk);
                                                                     XCTAssertTrue([result3 hasFirst]);
                                                                     XCTAssertFalse([result3 hasNext]);
                                                                     NSArray * page = [result3 currentItems];
                                                                     XCTAssertEqual([page count], 1);
                                                                     ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                     XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                                                                     [result3 getFirstPage:^(ARTStatus status, id<ARTPaginatedResult> result4) {
                                                                         XCTAssertEqual(status, ARTStatusOk);
                                                                         XCTAssertTrue([result4 hasFirst]);
                                                                         XCTAssertTrue([result4 hasNext]);
                                                                         NSArray * page = [result4 currentItems];
                                                                         XCTAssertEqual([page count], 2);
                                                                         ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                         ARTMessage * secondMessage =[page objectAtIndex:1];
                                                                         XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                                                                         XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                                                                         [expectation fulfill];
                                                                     }];
                                                                 }];
                                                             }];
                                                         }];
                        }];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}





@end
