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
#import "ARTAppSetup.h"
@interface ARTRestAppStatsTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestAppStatsTest

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
        [ARTAppSetup setupApp:_options cb:^(ARTOptions *options) {
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
    XCTFail(@"TODO write test");
}
- (void)testMinuteBackwards {
    // This is an example of a functional test case.
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
