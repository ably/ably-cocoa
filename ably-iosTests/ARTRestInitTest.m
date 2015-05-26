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
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTOptions+Private.h"

@interface ARTRestInitTest : XCTestCase {
    ARTRest *_rest;
}
@end

@implementation ARTRestInitTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [ARTOptions getDefaultRestHost:@"rest.ably.io" modify:true];
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
    [ARTOptions getDefaultRestHost:@"sandbox-rest.ably.io" modify:true];
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKey"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        NSString * keyName = options.authOptions.keyName;
        NSString * keySecret = options.authOptions.keySecret;
        NSString * key = [NSString stringWithFormat:@"%@:%@",keyName, keySecret];
        [ARTRest restWithKey:key cb:^(ARTRest *rest) {
            _rest =rest;
            ARTRestChannel * c = [rest channel:@"test"];
            XCTAssert(c);
            [c publish:@"message" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithNoKey {
    [ARTOptions getDefaultRestHost:@"sandbox-rest.ably.io" modify:true];
    NSString * key = @"";
    XCTAssertThrows([ARTRest restWithKey:key cb:^(ARTRest * rest) {}]);
}

-(void)testInitWithKeyBad {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKeyBad"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        NSString * keyName = @"badName";
        NSString * keySecret = options.authOptions.keySecret;
        NSString * key = [NSString stringWithFormat:@"%@:%@",keyName, keySecret];
        [ARTRest restWithKey:key cb:^(ARTRest * rest) {
            _rest =rest;
            ARTRestChannel * c = [rest channel:@"test"];
            XCTAssert(c);
            [c publish:@"message" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusError, status.status);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptions {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
       [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest =rest;
           ARTRestChannel * c = [rest channel:@"test"];
           XCTAssert(c);
           [c publish:@"message" cb:^(ARTStatus *status) {
               XCTAssertEqual(ARTStatusOk, status.status);
               [exp fulfill];
           }];
       }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithOptionsEnvironment {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        ARTOptions *envOptions =[ARTOptions options];
        envOptions.authOptions.keyName = options.authOptions.keyName;
        envOptions.authOptions.keySecret = options.authOptions.keySecret;
        envOptions.environment = @"sandbox";
        [ARTRest restWithOptions:envOptions cb:^(ARTRest * rest) {
            _rest =rest;
            ARTRestChannel * c = [rest channel:@"test"];
            [c publish:@"message" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testGetAuth {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest =rest;
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
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


-(void)testInitWithOptionsBad {
    XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithOptions"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.keyName = @"bad:Name";
        XCTAssertThrows([ARTRest restWithOptions:options cb:^(ARTRest *rest) {}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testRestTimeBadHost {
    XCTestExpectation *exp = [self expectationWithDescription:@"testRestTimeBadHost"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.restHost = @"this.host.does.not.exist";
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest =rest;
            [rest time:^(ARTStatus *status, NSDate *date) {
                XCTAssertEqual(ARTStatusError, status.status);
                [exp fulfill];
            }];
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
