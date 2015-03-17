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

- (void)withRest:(void(^)(ARTRest *))cb;
- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay;

@end

@implementation ARTRestChannelHistoryTest


const float SMALL_SLEEP = 2.00;
const float BIG_SLEEP = 3.0;
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


//TODO testTypes test?



-(void) testTimeBackwards
{

    XCTestExpectation *e = [self expectationWithDescription:@"realtime"];
    
    //TODO whats this for.
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        __weak  XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_first_batch"];
        ARTRestChannel *channel = [rest channel:@"test_history_time_forwards"];
        
        int firstBatchTotal =3;
        int secondBatchTotal =2;
        int thirdBatchTotal =1;
        long long intervalStart=0, intervalEnd=0;
        
        //send first batch, which we won't recieve in the history request
        {
            __block int numReceived =0;
            
            for(int i=0; i < firstBatchTotal; i++) {

                NSString * pub = [NSString stringWithFormat:@"test%d", i];
                sleep(SMALL_SLEEP);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived;
                    if(numReceived ==firstBatchTotal) {
                        [firstExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        __weak  XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        //send second batch (which we will retrieve via interval history request
        {
            
            sleep(BIG_SLEEP);
            intervalStart  = [ARTTestUtil nowMilli];
            __block int numReceived2 =0;
            
            for(int i=0; i < secondBatchTotal; i++) {
                NSString * pub = [NSString stringWithFormat:@"second_test%d", i];
                sleep(SMALL_SLEEP);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived2;
                    if(numReceived2 ==secondBatchTotal) {
                        [secondExpecation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep(BIG_SLEEP);
        intervalEnd = [ARTTestUtil nowMilli];
        __weak  XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        //send third batch, which we won't receieve in the history request
        {
            __block int numReceived3 =0;
            
            for(int i=0; i < thirdBatchTotal; i++) {
                NSLog(@"third batchb %d", i);
                NSString * pub = [NSString stringWithFormat:@"third_test%d", i];
                sleep(SMALL_SLEEP);
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
    XCTestExpectation *e = [self expectationWithDescription:@"realtime"];
    
    //TODO whats this for.
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        __weak  XCTestExpectation *firstExpectation = [self expectationWithDescription:@"send_first_batch"];
        ARTRestChannel *channel = [rest channel:@"test_history_time_forwards"];
 
        int firstBatchTotal =10;
        int secondBatchTotal =5;
        long long intervalStart=0, intervalEnd=0;
        
        //send first batch, which we won't recieve in the history request
        {
            

            __block int numReceived =0;

            for(int i=0; i < firstBatchTotal; i++) {
 
                NSLog(@"first batch %d", i);
                NSString * pub = [NSString stringWithFormat:@"test%d", i];
                sleep(SMALL_SLEEP);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived;
                    if(numReceived ==firstBatchTotal) {
                        [firstExpectation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        __weak  XCTestExpectation *secondExpecation = [self expectationWithDescription:@"send_second_batch"];
        //send second batch (which we will retrieve via interval history request
        {
            sleep(BIG_SLEEP);
            intervalStart  = [ARTTestUtil nowMilli];
            __block int numReceived2 =0;

            for(int i=0; i < secondBatchTotal; i++) {
                NSLog(@"second batch %d", i);
                NSString * pub = [NSString stringWithFormat:@"second_test%d", i];
                sleep(SMALL_SLEEP);
                [channel publish:pub cb:^(ARTStatus status) {
                    ++numReceived2;
                    if(numReceived2 ==secondBatchTotal) {
                        [secondExpecation fulfill];
                    }
                }];
            }
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        sleep(BIG_SLEEP);
        intervalEnd = [ARTTestUtil nowMilli];
        __weak  XCTestExpectation *thirdExpectation = [self expectationWithDescription:@"send_third_batch"];
        //send third batch, which we won't receieve in the history request
        {
            __block int numReceived3 =0;
            
            for(int i=0; i < secondBatchTotal; i++) {
                NSLog(@"third batch %d", i);
                NSString * pub = [NSString stringWithFormat:@"third_test%d", i];
                sleep(SMALL_SLEEP);
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

//TODO I've merged tests here into 2.
-(void) testHistoryForwardPagination
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [self withRest:^(ARTRest  *rest) {
        ARTRestChannel *channel = [rest channel:@"histChan"];
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardagination"];
    [self withRest:^(ARTRest  *rest) {
        ARTRestChannel *channel = [rest channel:@"histBackChan"];
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
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
