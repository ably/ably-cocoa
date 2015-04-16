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
@interface ARTRestChannelPublishTest : XCTestCase
{
    ARTRest *_restText;
    ARTRest *_restBinary;
    ARTOptions *_textOptions;
    ARTOptions *_binaryOptions;
    float _timeout;
}


@end

@implementation ARTRestChannelPublishTest

- (void)setUp {
    [super setUp];
    _textOptions = [[ARTOptions alloc] init];
    _textOptions.restHost = [ARTTestUtil restHost];
    _textOptions.binary = false;
    
    _binaryOptions = [[ARTOptions alloc] init];
    _binaryOptions.restHost = [ARTTestUtil restHost];
    _binaryOptions.binary = true;
    _timeout = [ARTTestUtil timeout];
}

- (void)tearDown {
    _restBinary = nil;
    _restText = nil;
    
    [super tearDown];
}

- (void)withRestText:(void (^)(ARTRest *rest))cb {
    if (!_restText) {
        [ARTTestUtil setupApp:_textOptions cb:^(ARTOptions *options) {
            if (options) {
                _restText = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_restText);
        }];
        return;
    }
    cb(_restText);
}

- (void)withRestBinary:(void (^)(ARTRest *rest))cb {
    if (!_restBinary) {
        [ARTTestUtil setupApp:_binaryOptions cb:^(ARTOptions *options) {
            if (options) {
                _restBinary = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_restBinary);
        }];
        return;
    }
    cb(_restText);
}

- (void)testTypesByText {

    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    [self withRestText:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"testTypesByText"];
        [channel publish:message1 cb:^(ARTStatus status) {
            XCTAssertEqual(ARTStatusOk, status);
            [channel publish:message2 cb:^(ARTStatus status) {
                XCTAssertEqual(ARTStatusOk, status);
                [channel historyWithParams:@{ @"direction" : @"forwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
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
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}

/*
 //msgpack not implemented yet
- (void)testTypesByBinary {

}

 */
@end
