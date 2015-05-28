//
//  ARTRestChannelPublishTest.m
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
#import "ARTPayload+Private.h"
#import "ARTLog.h"

@interface ARTRestChannelPublishTest : XCTestCase
{
    ARTRest * _rest;
}
@end

@implementation ARTRestChannelPublishTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    _rest = nil;
}

- (void)testTypesByText {

    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest channel:@"testTypesByText"];
        [channel publish:message1 cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel publish:message2 cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [channel historyWithParams:@{ @"direction" : @"forwards"} cb:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    NSArray *messages = [result currentItems];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects([m0 content], message1);
                    XCTAssertEqualObjects([m1 content], message2);
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPublishArray {
    XCTFail(@"TODO FINISH");
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishArray"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest channel:@"channel"];
        NSString * test1 = @"test1";
        NSString * test2 = @"test2";
        NSString * test3 = @"test3";
        NSArray * messages = @[test1, test2, test3];
        [channel publish:messages cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [channel history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                XCTAssertEqual(ARTStatusOk, status.status);
                NSArray *messages = [result currentItems];
                XCTAssertEqual(3, messages.count);
                ARTMessage *m0 = messages[0];
                ARTMessage *m1 = messages[1];
                ARTMessage *m2 = messages[2];
                XCTAssertEqualObjects([m0 content], test3);
                XCTAssertEqualObjects([m1 content], test2);
                XCTAssertEqualObjects([m2 content], test1);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPublishTooManyInArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishTooManyInArray"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest channel:@"channel"];
        NSArray * messages = @[@"test1", @"test2", @"test3"];
        [ARTPayload getPayloadArraySizeLimit:2 modify:true];
        XCTAssertThrows([channel publish:messages cb:^(ARTStatus *status) {}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishUnJsonableType {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest channel:@"testTypesByText"];
        XCTAssertThrows([channel publish:channel cb:^(ARTStatus *status){}]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}




@end
