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
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions+Private.h"

@interface ARTRestInitTest : XCTestCase {
    ARTRest *_rest;
}
@end

@implementation ARTRestInitTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [ARTClientOptions getDefaultRestHost:@"rest.ably.io" modify:true];
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
    [ARTClientOptions getDefaultRestHost:@"sandbox-rest.ably.io" modify:true];
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKey"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        NSString * keyName = options.authOptions.keyName;
        NSString * keySecret = options.authOptions.keySecret;
        NSString * key = [NSString stringWithFormat:@"%@:%@",keyName, keySecret];
        ARTRest * rest = [[ARTRest alloc] initWithKey:key];
        _rest = rest;
        ARTRestChannel * c = [rest channel:@"test"];
        XCTAssert(c);
        [c publish:@"message" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithNoKey {
    [ARTClientOptions getDefaultRestHost:@"sandbox-rest.ably.io" modify:true];
    NSString * key = @"";
    XCTAssertThrows([[ARTRest alloc] initWithKey:key]);
}

-(void)testInitWithKeyBad {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKeyBad"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        NSString * keyName = @"badName";
        NSString * keySecret = options.authOptions.keySecret;
        NSString * key = [NSString stringWithFormat:@"%@:%@",keyName, keySecret];
        ARTRest * rest = [[ARTRest alloc] initWithKey:key];
        _rest = rest;
        ARTRestChannel * c = [rest channel:@"test"];
        XCTAssert(c);
        [c publish:@"message" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusError, status.status);
            XCTAssertEqual(40005, status.errorInfo.code);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptions {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
       ARTRestChannel * c = [rest channel:@"test"];
       XCTAssert(c);
       [c publish:@"message" cb:^(ARTStatus *status) {
           XCTAssertEqual(ARTStatusOk, status.status);
           [exp fulfill];
       }];
   }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptionsEnvironment {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        ARTClientOptions *envOptions =[ARTClientOptions options];
        envOptions.authOptions.keyName = options.authOptions.keyName;
        envOptions.authOptions.keySecret = options.authOptions.keySecret;
        envOptions.environment = @"sandbox";
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTRestChannel * c = [rest channel:@"test"];
        [c publish:@"message" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testGetAuth {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        ARTRestChannel * c = [rest channel:@"test"];
        XCTAssert(c);
        [c publish:@"message" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            ARTAuth * auth = rest.auth;
            XCTAssert(auth);
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            XCTAssertEqual(authOptions.keyName, options.authOptions.keyName);
            [exp fulfill];
        }];

    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptionsBad {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        options.authOptions.keyName = @"bad:Name";
        XCTAssertThrows([[ARTRest alloc] initWithOptions:options]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testRestTimeNoFallbackHost {
    XCTestExpectation *exp = [self expectationWithDescription:@"testRestTimeBadHost"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTClientOptions *options) {
        NSString * badHost = @"this.host.does.not.exist";
        options.restHost = badHost;
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        _rest = rest;
        [rest time:^(ARTStatus *status, NSDate *date) {
            XCTAssertEqual(ARTStatusError, status.status);
            NSString * badUrl =[@"https://" stringByAppendingString:[badHost stringByAppendingString:@":443"]];
            XCTAssertEqualObjects([[rest getBaseURL] absoluteString], badUrl);
            [exp fulfill];
        }];

    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testRestTime {
    XCTestExpectation *exp = [self expectationWithDescription:@"testRestTime"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest =rest;
        [rest time:^(ARTStatus *status, NSDate *date) {
            XCTAssertEqual(ARTStatusOk, status.status);
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
        XCTAssertEqual([[rest auth] getAuthMethod], ARTAuthMethodBasic);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



@end
