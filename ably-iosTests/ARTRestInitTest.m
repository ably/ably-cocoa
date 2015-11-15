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
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAuth.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions.h"
#import "ARTChannel.h"
#import "ARTChannelCollection.h"


@interface ARTRestInitTest : XCTestCase {
    ARTRest *_rest;
}
@end

@implementation ARTRestInitTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

-(void)testInternetIsUp {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInternetIsUp"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        [rest internetIsUp:^(bool isUp) {
            XCTAssertTrue(isUp);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithKey {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKey"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRest *rest = [[ARTRest alloc] initWithKey:options.key];
        _rest = rest;
        ARTChannel *c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:@"message" callback:^(NSError *error) {
            // "Invalid credentials" because it is sending the request to the production server
            XCTAssert(error);
            XCTAssertEqual(error.code, 40100);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithNoKey {
    NSString * key = @"";
    XCTAssertThrows([[ARTRest alloc] initWithKey:key]);
}

-(void)testInitWithKeyBad {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKeyBad"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithKey:@"badkey:secret"];
        _rest = rest;
        ARTChannel * c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:@"message" callback:^(NSError *error) {
            XCTAssert(error);
            XCTAssertEqual(40005, error.code);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptions {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
       ARTChannel * c = [rest.channels get:@"test"];
       XCTAssert(c);
       [c publish:@"message" callback:^(NSError *error) {
           XCTAssert(!error);
           [exp fulfill];
       }];
   }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptionsEnvironment {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTClientOptions *envOptions = [[ARTClientOptions alloc] init];
        envOptions.key = options.key;
        envOptions.environment = @"sandbox";
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTChannel * c = [rest.channels get:@"test"];
        [c publish:@"message" callback:^(NSError *error) {
            XCTAssert(!error);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testGetAuth {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTChannel * c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:@"message" callback:^(NSError *error) {
            XCTAssert(!error);
            ARTAuth * auth = rest.auth;
            XCTAssert(auth);
            ARTAuthOptions *authOptions = auth.options;
            XCTAssertEqual(authOptions.key, options.key);
            [exp fulfill];
        }];

    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptionsBad {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        options.key = @"bad:Name";
        XCTAssertThrows([[ARTRest alloc] initWithOptions:options]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testRestTime {
    XCTestExpectation *exp = [self expectationWithDescription:@"testRestTime"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        [rest time:^(NSDate *date, NSError *error) {
            XCTAssert(error);
            // Expect local clock and server clock to be synced within 10 seconds
            XCTAssertEqualWithAccuracy([date timeIntervalSinceNow], 0.0, 10.0);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testDefaultAuthType {
    XCTestExpectation *exp = [self expectationWithDescription:@"testRestTime"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        XCTAssertEqual([rest.auth method], ARTAuthMethodBasic);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
