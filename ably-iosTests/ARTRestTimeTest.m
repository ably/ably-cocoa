//
//  ARTRestTimeTest.m
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

@interface ARTRestTimeTest : XCTestCase {
    ARTRest *_rest;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestTimeTest

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

- (void)testRestTimeBadHost {
    __weak XCTestExpectation *expectationRestTimeBadHost = [self expectationWithDescription:@"testRestTimeBadHost"];
    
    ARTOptions * badOptions = [[ARTOptions alloc] init];
    badOptions.restHost = @"this.host.does.not.exist";
    
    [ARTTestUtil setupApp:badOptions cb:^(ARTOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        [rest time:^(ARTStatus status, NSDate *date) {
            XCTAssert(status == ARTStatusError);
            if(expectationRestTimeBadHost) {
                [expectationRestTimeBadHost fulfill];
                
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testRestTime {
    __weak XCTestExpectation *expectationRestTime = [self expectationWithDescription:@"testRestTime"];
    
    [self withRest:^(ARTRest *rest) {
        [rest time:^(ARTStatus status, NSDate *date) {
            XCTAssert(status == ARTStatusOk);
            // Expect local clock and server clock to be synced within 5 seconds
            XCTAssertEqualWithAccuracy([date timeIntervalSinceNow], 0.0, 5.0);
            
            if(status == ARTStatusOk) {
                if(expectationRestTime) {
                    [expectationRestTime fulfill];
                }
                
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
