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
#import "ARTClientOptions+Private.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAuth.h"
#import "ARTAuth+Private.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions.h"
#import "ARTChannel.h"
#import "ARTChannels.h"

@interface ARTRestInitTest : XCTestCase {
    ARTRest *_rest;
}

@end

@implementation ARTRestInitTest

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

- (void)testInternetIsUp {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInternetIsUp"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [rest internetIsUp:^(bool isUp) {
            XCTAssertTrue(isUp);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithKey {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKey"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        @try {
            [ARTClientOptions setDefaultEnvironment:@"sandbox"];
            ARTRest *rest = [[ARTRest alloc] initWithKey:options.key];
            _rest = rest;
            ARTChannel *c = [rest.channels get:@"test"];
            XCTAssert(c);
            [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
                XCTAssertNil(error);
                [exp fulfill];
            }];
        }
        @finally {
            [ARTClientOptions setDefaultEnvironment:nil];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithNoKey {
    NSString *key = @"";
    XCTAssertThrows([[ARTRest alloc] initWithKey:key]);
}

- (void)testInitWithKeyBad {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKeyBad"];
    @try {
        [ARTClientOptions setDefaultEnvironment:@"sandbox"];
        ARTRest *rest = [[ARTRest alloc] initWithKey:@"badkey:secret"];
        _rest = rest;
        ARTChannel *c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
            XCTAssert(error);
            XCTAssertEqual(40005, error.code); //invalid credential
            [exp fulfill];
        }];
    }
    @finally {
        [ARTClientOptions setDefaultEnvironment:nil];
    }
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithOptions {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTChannel *c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithOptionsEnvironment {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        ARTClientOptions *envOptions = [[ARTClientOptions alloc] init];
        envOptions.key = options.key;
        envOptions.environment = @"sandbox";
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTChannel *c = [rest.channels get:@"test"];
        [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testGetAuth {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTChannel *c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            ARTAuth *auth = rest.auth;
            XCTAssert(auth);
            ARTAuthOptions *authOptions = auth.options;
            XCTAssertEqual(authOptions.key, options.key);
            [exp fulfill];
        }];

    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithOptionsBad {
    XCTAssertThrows([[ARTClientOptions alloc] initWithKey:@"bad"]);
    XCTAssertThrows([[ARTRest alloc] initWithOptions:[[ARTClientOptions alloc] init]]);
}

- (void)testRestTime {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testRestTime"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest time:^(NSDate *date, NSError *error) {
            XCTAssert(!error);
            // Expect local clock and server clock to be synced within 30 seconds
            XCTAssertEqualWithAccuracy([date timeIntervalSinceNow], 0.0, 30.0);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testDefaultAuthType {
    ARTRest* rest = [[ARTRest alloc] initWithKey:@"key:secret"];
    XCTAssertEqual([rest.auth method], ARTAuthMethodBasic);
}

@end
