//
//  ARTRestPresenceTest.m
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
@interface ARTRestPresenceTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;

}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestPresenceTest

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

- (void)testPresence {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            if(status != ARTStatusOk) {
                XCTFail(@"not an ok status");
                [expectation fulfill];
                return;
            }
            NSArray *presence = [result currentItems];
            XCTAssertEqual(4, presence.count);
            ARTPresenceMessage *p0 = presence[0];
            ARTPresenceMessage *p1 = presence[1];
            ARTPresenceMessage *p2 = presence[2];
            ARTPresenceMessage *p3 = presence[3];
            
            
            // This is assuming the results are coming back sorted by clientId
            // in alphabetical order. This seems to be the case at the time of
            // writing, but may change in the future
            
            XCTAssertEqualObjects(@"client_bool", p0.clientId);
            XCTAssertEqualObjects(@"true", [p0 content]);
            
            XCTAssertEqualObjects(@"client_int", p1.clientId);
            XCTAssertEqualObjects(@"24", [p1 content]);
            
            XCTAssertEqualObjects(@"client_json", p2.clientId);
            XCTAssertEqualObjects(@"{\"test\":\"This is a JSONObject clientData payload\"}", [p2 content]);
            
            XCTAssertEqualObjects(@"client_string", p3.clientId);
            XCTAssertEqualObjects(@"This is a string clientData payload", [p3 content]);
            
            
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistory {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presenceHistory:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            if(status != ARTStatusOk) {
                XCTFail(@"not an ok status");
                [expectation fulfill];
                return;
            }
            NSArray *presence = [result currentItems];
            XCTAssertEqual(4, presence.count);
            [expectation fulfill];

        }];
    }];
     [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
- (void)testHistoryBinary {
    XCTFail(@"TODO write test");
}
- (void)testTypesBinary {
    XCTFail(@"TODO write test");
}
*/
@end
