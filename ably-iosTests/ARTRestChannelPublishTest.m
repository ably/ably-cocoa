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
            NSLog(@"BINARY IS A %@", (options.binary ? @"YES" : @"NO"));
            cb(_restBinary);
        }];
        return;
    }
    cb(_restText);
}

- (void)testTypesByText {

    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [self withRestText:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            if(status != ARTStatusOk) {
                XCTFail(@"not an ok status");
                [expectation fulfill];
                return;
            }
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
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}
- (void)testTypesByBinary {
    
    XCTFail(@"TODO Crashes in websocket");
    return;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [self withRestBinary:^(ARTRest *rest) {
        NSLog(@"withRestbinary");
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    NSLog(@"presence...");
            XCTAssertEqual(status, ARTStatusOk);
            if(status != ARTStatusOk) {
                XCTFail(@"not an ok status");
                [expectation fulfill];
                return;
            }
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
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}

@end
