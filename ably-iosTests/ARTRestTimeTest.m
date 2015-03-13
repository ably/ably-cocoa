//
//  ARTRestTimeTest.m
//  ably-ios
//
//  Created by vic on 13/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAppSetup.h"

@interface ARTRestTimeTest : XCTestCase {
    ARTRest *_rest;
    float _timeout;
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
        [ARTAppSetup setupApp:[ARTAppSetup jsonRestOptions] cb:^(ARTOptions *options) {
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTime"];
    
    ARTOptions * badOptions = [[ARTOptions alloc] init];
    badOptions.restHost = @"this.host.does.not.exist";
    
    [ARTAppSetup setupApp:badOptions cb:^(ARTOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        [rest time:^(ARTStatus status, NSDate *date) {
            NSLog(@"status bad host is %d", status);
            NSLog(@"nsdate is %@", date);
            XCTAssert(status == ARTStatusError);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTAppSetup timeout] handler:nil];
}

- (void)testRestTime {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTime"];
    
    [self withRest:^(ARTRest *rest) {
        [rest time:^(ARTStatus status, NSDate *date) {
            NSLog(@"status is %d", status);
            NSLog(@"nsdate is %@", date);
            XCTAssert(status == ARTStatusOk);
            // Expect local clock and server clock to be synced within 5 seconds
            XCTAssertEqualWithAccuracy([date timeIntervalSinceNow], 0.0, 5.0);
            
            if(status == ARTStatusOk) {
                [expectation fulfill];
            }
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTAppSetup timeout] handler:nil];
}
@end
