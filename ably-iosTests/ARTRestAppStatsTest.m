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
@interface ARTRestAppStatsTest : XCTestCase {
    ARTRest *_rest;
   // ARTOptions *_options;
//    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestAppStatsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

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

- (void)testStatsBaseTODORM {
   
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
        XCTestExpectation *expectation = [self expectationWithDescription:@"stats"];
        
        NSLog(@"here comes the stats bit");
        [rest stats:^(ARTStatus status, id<ARTPaginatedResult> result) {
            NSLog(@"stats called back with %@, %d", result, status);
            
            NSArray * page = [result current];
            NSLog(@"PAGE IS %@", page);
            
            XCTAssertEqual([page count], 1);
            XCTAssertEqual(status, ARTStatusOk);
            XCTAssertNotNil([result current]);
            ARTStats * statObj = [page objectAtIndex:0];
            NSLog(@"STAT IS %@", statObj);
            if(status == ARTStatusOk) {
                [expectation fulfill];
            }
            
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
    
}


-(void)testMinuteForwards {
    XCTFail(@"TODO write test");
}

- (void)testMinuteBackwards {
    XCTFail(@"TODO write test");
}

-(void) testHourForwards {
    XCTFail(@"TODO write test");
}

-(void)testDayFowards {
    XCTFail(@"TODO write test");
}

-(void)testMonthForwards {
    XCTFail(@"TODO write test");
}

-(void)testLimitBackwards {
    XCTFail(@"TODO write test");
}

-(void) testLimitForwards {
    XCTFail(@"TODO write test");
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


@end
