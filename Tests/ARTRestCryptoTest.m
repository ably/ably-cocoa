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
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTTestUtil.h"
#import "ARTCrypto+Private.h"
#import "ARTLog.h"
#import "ARTRestChannel.h"
#import "ARTChannelOptions.h"
#import "ARTChannels.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"

@interface ARTRestCryptoTest : XCTestCase

@end

@implementation ARTRestCryptoTest

- (void)tearDown {
    [super tearDown];
}

- (void)testSendBinary {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTChannel *c = [rest.channels get:@"test"];
    XCTAssert(c);
    NSData *dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
    NSString *stringPayload = @"someString";
    [c publish:nil data:dataPayload callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [c publish:nil data:stringPayload callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [c history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                XCTAssert(!error);
                NSArray *page = [result items];
                XCTAssertTrue(page != nil);
                XCTAssertEqual([page count], 2);
                ARTMessage *stringMessage = [page objectAtIndex:0];
                ARTMessage *dataMessage = [page objectAtIndex:1];
                XCTAssertEqualObjects([dataMessage data], dataPayload);
                XCTAssertEqualObjects([stringMessage data], stringPayload);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSendEncodedMessage {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    NSData *ivSpec = [[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0];
    NSData *keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
    ARTCipherParams *params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" key:keySpec iv:ivSpec];
    ARTChannelOptions *channelOptions = [[ARTChannelOptions alloc] initWithCipher:params];
    ARTRestChannel *c = [rest.channels get:@"test" options:channelOptions];
    XCTAssert(c);
    NSData *dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
    NSString *stringPayload = @"someString";
    [c publish:nil data:dataPayload callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [c publish:nil data:stringPayload callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [c history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                XCTAssert(!error);
                NSArray *page = [result items];
                XCTAssertTrue(page != nil);
                XCTAssertEqual([page count], 2);
                ARTMessage *stringMessage = [page objectAtIndex:0];
                ARTMessage *dataMessage = [page objectAtIndex:1];
                XCTAssertEqualObjects([dataMessage data], dataPayload);
                XCTAssertEqualObjects([stringMessage data], stringPayload);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
