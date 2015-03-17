//
//  ARTRestCrytoTest.m
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
@interface ARTRestCryptoTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestCryptoTest

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
- (void)testPublishText {
    XCTFail(@"TODO write test");
}
- (void)testPublishBinary {
    XCTFail(@"TODO write test");
}
- (void)testPublishText256 {
    XCTFail(@"TODO write test");
}

- (void)testBinary256 {
    XCTFail(@"TODO write test");
}

- (void)testTextAndBinary {
    XCTFail(@"TODO write test");
}

- (void)testBinaryAndText {
    XCTFail(@"TODO write test");
}

- (void)testPublishKeyMismatch {
    XCTFail(@"TODO write test");
}

- (void)testSendUnencrypted {
    XCTFail(@"TODO write test");
}

- (void)testEncrypedUnHandled {
    XCTFail(@"TODO write test");
}




@end
