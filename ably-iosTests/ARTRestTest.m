//
//  ARTRestTest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAppSetup.h"

@interface ARTRestTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
}

- (void)withRest:(void(^)(ARTRest *))cb;

@end

@implementation ARTRestTest

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

- (void)testTime {
    XCTestExpectation *expectation = [self expectationWithDescription:@"get"];

    [self withRest:^(ARTRest *rest) {
        [rest time:^(ARTStatus status, NSDate *date) {
            XCTAssert(status == ARTStatusOk);
            // Expect local clock and server clock to be synced within 5 seconds
            XCTAssertEqualWithAccuracy([date timeIntervalSinceNow], 0.0, 5.0);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testPublish {
    XCTestExpectation *expectation = [self expectationWithDescription:@"publish"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"test"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testStats {
    XCTestExpectation *expectation = [self expectationWithDescription:@"stats"];
    [self withRest:^(ARTRest *rest) {
        [rest stats:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            XCTAssertNotNil([result current]);
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testHistory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"waitForPublish"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];

                    XCTAssertEqualObjects(@"testString2", m0.payload);
                    XCTAssertEqualObjects(@"testString", m1.payload);

                    [expectation fulfill];
                }];
            }];
        }];
    }];

    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testPresence {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            NSArray *presence = [result current];
            XCTAssertEqual(4, presence.count);
            ARTPresenceMessage *p0 = presence[0];
            ARTPresenceMessage *p1 = presence[1];
            ARTPresenceMessage *p2 = presence[2];
            ARTPresenceMessage *p3 = presence[3];

            // This is assuming the results are coming back sorted by clientId
            // in alphabetical order. This seems to be the case at the time of
            // writing, but may change in the future

            XCTAssertEqualObjects(@"client_bool", p0.clientId);
            XCTAssertEqualObjects(@"true", p0.payload);

            XCTAssertEqualObjects(@"client_int", p1.clientId);
            XCTAssertEqualObjects(@"24", p1.payload);

            XCTAssertEqualObjects(@"client_json", p2.clientId);
            XCTAssertEqualObjects(@"{\"test\":\"This is a JSONObject clientData payload\"}", p2.payload);

            XCTAssertEqualObjects(@"client_string", p3.clientId);
            XCTAssertEqualObjects(@"This is a string clientData payload", p3.payload);


            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
