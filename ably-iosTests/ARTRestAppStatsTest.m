//
//  ARTRestAppStatsTest.m
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
#import "ARTStats.h"
#import "ARTNSDate+ARTUtil.h"
@interface ARTRestAppStatsTest : XCTestCase {
    ARTRest *_rest;
}



@end

@implementation ARTRestAppStatsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}
/* 
 //stats not fully tested yet.
 
- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}


-(void)testMinuteForwards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];


        
        
        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityMinutes];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityMinutes];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityMinutes];

        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr
                                } cb:
        ^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            XCTAssertNotNil([result current]);
            NSArray * page = [result current];
            XCTAssertEqual([page count], 1);
            ARTStats * statObj = [page objectAtIndex:0];
            //TODO write tests

            NSLog(@"stats called back with %@, %d", result, status);
            NSLog(@"PAGE IS %@", page);
            [threeMinExpectation fulfill];
        }];
        XCTestExpectation *twoMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : twoMinAgoStr,
                                @"end" : twoMinAgoStr
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             
             NSLog(@"stats 2min called back with %@, %d", result, status);
             NSLog(@"PAGE 2min IS %@", page);
             [twoMinExpectation fulfill];
         }];
        XCTestExpectation *oneMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : oneMinAgoStr,
                                @"end" : oneMinAgoStr
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             
             NSLog(@"stats 1min called back with %@, %d", result, status);
             NSLog(@"PAGE 1min IS %@", page);
             [oneMinExpectation fulfill];
         }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

- (void)testMinuteBackwards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        //TODO do i need to populate this? RM I thnk
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityMinutes];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityMinutes];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityMinutes];
        
        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"backwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             
             NSLog(@"stats called backwards back with %@, %d", result, status);
             NSLog(@"PAGE IS %@", page);
             [threeMinExpectation fulfill];
         }];
    }];
}

-(void) testHourForwards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        //TODO do i need to populate this? RM I thnk
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        
        //TODO these are wrong.
        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityHours];
        
        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr,
                                @"unit" : @"hour"
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             
             NSLog(@"stats called backwards back with %@, %d", result, status);
             NSLog(@"PAGE IS %@", page);
             [threeMinExpectation fulfill];
         }];
    }];

}

-(void)testDayFowards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        //TODO do i need to populate this? RM I thnk
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        
        //TODO these are wrong.
        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityHours];
        
        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr,
                                @"unit" : @"day"
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             NSLog(@"stats called backwards back with %@, %d", result, status);
             NSLog(@"PAGE IS %@", page);
             [threeMinExpectation fulfill];
         }];
    }];
}

-(void)testMonthForwards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        //TODO do i need to populate this? RM I thnk
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        
        //TODO these are wrong.
        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityHours];
        
        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr,
                                @"unit" : @"month"
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             
             NSLog(@"stats called backwards back with %@, %d", result, status);
             NSLog(@"PAGE IS %@", page);
             [threeMinExpectation fulfill];
         }];
    }];
}

-(void)testLimitBackwards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        //TODO do i need to populate this? RM I thnk
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        
        //TODO these are wrong.
        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityHours];
        
        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"backwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr,
                                @"limit" : @"1"

                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];

             //TODO write tests
             
             NSLog(@"stats called backwards back with %@, %d", result, status);
             NSLog(@"PAGE IS %@", page);
             [threeMinExpectation fulfill];
         }];
    }];
}

-(void) testLimitForwards {
    XCTestExpectation *e = [self expectationWithDescription:@"init"];
    [self withRest:^(ARTRest *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRest:^(ARTRest *rest) {
        XCTestExpectation *populateExpectation = [self expectationWithDescription:@"testStatsPopulate"];
        ARTRestChannel *channel = [rest channel:@"testStats"];
        int totalMessages =20;
        __block int numReceived =0;
        
        //TODO do i need to populate this? RM I thnk
        for(int i=0; i < totalMessages; i++) {
            NSString * pub = [NSString stringWithFormat:@"messageForStat%d", i];
            [channel publish:pub cb:^(ARTStatus status) {
                ++numReceived;
                if(numReceived ==totalMessages) {
                    [populateExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        
        //TODO these are wrong.
        NSDate * date  = [NSDate date];
        date = [date dateByAddingTimeInterval:-60];
        NSString * oneMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * twoMinAgoStr = [date toIntervalFormat:GranularityHours];
        date = [date dateByAddingTimeInterval:-60];
        NSString * threeMinAgoStr = [date toIntervalFormat:GranularityHours];
        
        NSLog(@"here comes the stats bit");
        XCTestExpectation *threeMinExpectation = [self expectationWithDescription:@"stats"];
        [rest statsWithParams:@{
                                @"direction" : @"forwards",
                                @"start" : threeMinAgoStr,
                                @"end" : threeMinAgoStr,
                                @"limit" : @"1"
                                
                                } cb:
         ^(ARTStatus status, id<ARTPaginatedResult> result) {
             XCTAssertEqual(status, ARTStatusOk);
             XCTAssertNotNil([result current]);
             NSArray * page = [result current];
             XCTAssertEqual([page count], 1);
             ARTStats * statObj = [page objectAtIndex:0];
             //TODO write tests
             NSLog(@"stats called backwards back with %@, %d", result, status);
             NSLog(@"PAGE IS %@", page);
             [threeMinExpectation fulfill];
         }];
    }];
}
-(void) testPaginationBackwards {
    XCTFail(@"TODO write test");
}

-(void) testPaginationForwards {
    XCTFail(@"TODO write test");
}

-(void) testPaginationRelFirstBackwards {
    XCTFail(@"TODO write test");
}

-(void) testPaginationRelFirstForwards {
    XCTFail(@"TODO write test");
}

*/
@end
