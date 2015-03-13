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
#import "ARTAppSetup.h"
@interface ARTRestChannelHistoryTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;


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

- (void)testTypes {
    XCTFail(@"TODO write test");
}
- (void)testOrderForwards {
    XCTFail(@"TODO write test");
}
- (void)testOrderBackwards {
    XCTFail(@"TODO write test");
}
- (void)testLimitedHistoryForwards {
    XCTFail(@"TODO write test");
}
- (void)testLImitedHistoryBackwards {
    XCTFail(@"TODO write test");
}
- (void)testTimeForwards {
    XCTFail(@"TODO write test");
}
- (void)testTimeBackwards {
    XCTFail(@"TODO write test");
}
- (void)testPaginationForwards {
    XCTFail(@"TODO write test");
}
- (void)testPaginationBackwards {
    XCTFail(@"TODO write test");
}
- (void)testPaginateFirstForwards {
    XCTFail(@"TODO write test");
}
- (void)testPaginateFirstBackwards {
    XCTFail(@"TODO write test");
}


@end
