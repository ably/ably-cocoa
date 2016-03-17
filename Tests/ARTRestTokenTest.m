//
//  ARTRestTokenTest.m
//  ably-ios
//
//  Created by vic on 13/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTTestUtil.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTDataEncoder.h"
#import "ARTRestChannel.h"
#import "ARTChannels.h"
#import "ARTTokenDetails.h"
#import "ARTAuth.h"

@interface ARTRestTokenTest : XCTestCase {
    ARTRest *_rest;
    ARTRest *_rest2;
}

@end

@implementation ARTRestTokenTest

- (void)tearDown {
    _rest = nil;
    _rest2 = nil;
    [super tearDown];
}

- (void)testTokenSimple {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testRestTimeBadHost"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.useTokenAuth = true;
        options.clientId = @"testToken";
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTAuth *auth = rest.auth;
        XCTAssertEqual(auth.method, ARTAuthMethodToken);
        ARTRestChannel *c = [rest.channels get:@"getChannel"];
        [c publish:nil data:@"something" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithBadToken {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithToken"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.useTokenAuth = true;
        options.clientId = @"testToken";
        options.token = @"this_is_a_bad_token";
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTAuth *auth = rest.auth;
        XCTAssertEqual(auth.method, ARTAuthMethodToken);
        ARTChannel *c= [rest.channels get:@"getChannel"];
        [c publish:nil data:@"something" callback:^(ARTErrorInfo *error) {
            XCTAssert(error);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testAuthURLForcesToken {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testClientIdForcesToken"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.authUrl = [NSURL URLWithString:@"some_url"];
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTAuth *auth = rest.auth;
        XCTAssertEqual(auth.method, ARTAuthMethodToken);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testTTLDefaultOneHour {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testTTLDefaultOneHour"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = @"clientIdThatForcesToken";
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTAuth *auth = rest.auth;
        ARTChannel *c = [rest.channels get:@"getChannel"];
        [c publish:nil data:@"invokeTokenRequest" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            NSTimeInterval secs = [auth.tokenDetails.expires timeIntervalSinceDate:auth.tokenDetails.issued];
            XCTAssertEqual(secs, 3600);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithBorrowedAuthCb {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithToken"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.useTokenAuth = true;
        options.clientId = @"testToken";
        ARTRest *firstRest = [[ARTRest alloc] initWithOptions:options];
        _rest = firstRest;
        ARTAuth *auth = firstRest.auth;
        //options.authCallback = [auth getTheAuthCb]; //?!
        ARTRest *secondRest = [[ARTRest alloc] initWithOptions:options];
        _rest2 = secondRest;
        XCTAssertEqual(auth.method, ARTAuthMethodToken);
        ARTChannel *c = [secondRest.channels get:@"getChannel"];
        [c publish:nil data:@"something" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
