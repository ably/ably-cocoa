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
#import "ARTRest+Private.h"
#import "ARTLog.h"
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

-(NSString *) interval0 {
    return @"2015-03-13:05:22";
}
-(NSString *) interval1 {
    return @"2015-03-13:05:31";
}
-(NSString *) interval2 {
    return @"2015-03-13:15:20";
}
-(NSString *) interval3 {
    return @"2015-03-16:03:17";
}
-(NSArray *) getTestStats {
    return
       @[@{ @"intervalId": [self interval0],
            @"inbound": @{ @"realtime": @{@"messages":@{ @"count":[NSNumber numberWithInt:50],@"data":[NSNumber numberWithInt:5000]}}}},

        @{ @"intervalId": [self interval1],
           @"inbound": @{ @"realtime": @{@"messages":@{ @"count":[NSNumber numberWithInt:60],@"data":[NSNumber numberWithInt:6000]}}}},

        @{ @"intervalId": [self interval2],
           @"inbound": @{ @"realtime": @{@"messages":@{ @"count":[NSNumber numberWithInt:70],@"data":[NSNumber numberWithInt:7000]}}}},
         @{ @"intervalId": [self interval3],
            @"inbound": @{ @"realtime": @{@"messages":@{ @"count":[NSNumber numberWithInt:80],@"data":[NSNumber numberWithInt:8000]}}}},
         
        
        ];
}

-(void) testStatsDefaultBackwards {
    XCTestExpectation *exp = [self expectationWithDescription:@"init"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
       [rest postTestStats:[self getTestStats] cb:^(ARTStatus *status) {
           [rest statsWithParams:@{@"start":[self interval0], @"end": [self interval2]  } cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
               XCTAssertEqual(ARTStatusOk, status.status);
               NSArray * items = [result currentItems];

               XCTAssertEqual(3, [items count]);
               ARTStats * s = [items objectAtIndex:0];
               XCTAssertEqual(s.all.messages.count, 70.0);
               XCTAssertEqual(s.inbound.all.messages.count, 70.0);
               [exp fulfill];
           }];
       }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testStatsForwards {
    XCTestExpectation *exp = [self expectationWithDescription:@"init"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest postTestStats:[self getTestStats] cb:^(ARTStatus *status) {
            [rest statsWithParams:@{@"start":[self interval0], @"end": [self interval2] ,@"direction" : @"forwards" } cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                NSArray * items = [result currentItems];
                
                XCTAssertEqual(3, [items count]);
                ARTStats * s = [items objectAtIndex:0];
                XCTAssertEqual(s.all.messages.count, 50.0);
                XCTAssertEqual(s.inbound.all.messages.count, 50.0);
                [exp fulfill];
            }];
            
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testStatsHour {
    XCTestExpectation *exp = [self expectationWithDescription:@"init"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest postTestStats:[self getTestStats] cb:^(ARTStatus *status) {
            [rest statsWithParams:@{@"start":[self interval0], @"end": [self interval2] , @"unit" : @"hour" } cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                NSArray * items = [result currentItems];
                
                XCTAssertEqual(2, [items count]);
                ARTStats * s = [items objectAtIndex:0];
                XCTAssertEqual(s.all.messages.count, 110.0);
                XCTAssertEqual(s.inbound.all.messages.count, 110.0);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testStatsDay {
    XCTestExpectation *exp = [self expectationWithDescription:@"init"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest postTestStats:[self getTestStats] cb:^(ARTStatus *status) {
            [rest statsWithParams:@{@"start":[self interval0], @"end": [self interval3] , @"unit" : @"day", @"direction": @"forwards" } cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                NSArray * items = [result currentItems];
                
                XCTAssertEqual(2, [items count]);
                ARTStats * s = [items objectAtIndex:0];
                XCTAssertEqual(s.all.messages.count, 180.0);
                XCTAssertEqual(s.inbound.all.messages.count, 180.0);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
-(void) testStatsMonth {
    XCTestExpectation *exp = [self expectationWithDescription:@"init"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest postTestStats:[self getTestStats] cb:^(ARTStatus *status) {
            [rest statsWithParams:@{@"start":[self interval0], @"end": [self interval3] , @"unit" : @"month", @"direction": @"forwards" } cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                NSArray * items = [result currentItems];
                
                XCTAssertEqual(1, [items count]);
                ARTStats * s = [items objectAtIndex:0];
                XCTAssertEqual(s.all.messages.count, 260.0);
                XCTAssertEqual(s.inbound.all.messages.count, 260.0);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end