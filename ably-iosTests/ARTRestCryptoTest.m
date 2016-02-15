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
#import "ARTCrypto.h"
#import "ARTLog.h"
#import "ARTRestChannel.h"
#import "ARTChannelOptions.h"
#import "ARTChannels.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"

@interface ARTRestCryptoTest : XCTestCase {
    ARTRest *_rest;
}
@end

@implementation ARTRestCryptoTest

- (void)setUp {    
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

-(void) testSendBinary {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSendBinary"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest =rest;
        ARTChannel * c = [rest.channels get:@"test"];
        XCTAssert(c);
        NSData * dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
        NSString * stringPayload = @"someString";
        [c publish:nil data:dataPayload cb:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [c publish:nil data:stringPayload cb:^(ARTErrorInfo *error) {
                XCTAssert(!error);
                [c history:[[ARTDataQuery alloc] init] error:nil callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray * page = [result items];
                    XCTAssertTrue(page != nil);
                    XCTAssertEqual([page count], 2);
                    ARTMessage * stringMessage = [page objectAtIndex:0];
                    ARTMessage * dataMessage = [page objectAtIndex:1];
                    XCTAssertEqualObjects([dataMessage data], dataPayload);
                    XCTAssertEqualObjects([stringMessage data], stringPayload);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testSendEncodedMessage {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSendBinary"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest =rest;
        
        ARTIvParameterSpec * ivSpec = [[ARTIvParameterSpec alloc] initWithIv:[[NSData alloc]
                                                                              initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
    
        NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
        ARTCipherParams *params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" keySpec:keySpec ivSpec:ivSpec];
        ARTChannelOptions *channelOptions = [[ARTChannelOptions alloc] initEncrypted:params];

        ARTRestChannel *c = [rest.channels get:@"test" options:channelOptions];
        XCTAssert(c);
        NSData * dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
        NSString * stringPayload = @"someString";
        [c publish:nil data:dataPayload cb:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            [c publish:nil data:stringPayload cb:^(ARTErrorInfo *error) {
                XCTAssert(!error);
                [c history:[[ARTDataQuery alloc] init] error:nil callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray * page = [result items];
                    XCTAssertTrue(page != nil);
                    XCTAssertEqual([page count], 2);
                    ARTMessage * stringMessage = [page objectAtIndex:0];
                    ARTMessage * dataMessage = [page objectAtIndex:1];
                    XCTAssertEqualObjects([dataMessage data], dataPayload);
                    XCTAssertEqualObjects([stringMessage data], stringPayload);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



/*
- (void)testPublishText256 {
    XCTFail(@"TODO write test");
}




- (void)testPublishKeyMismatch {
    XCTFail(@"TODO write test");
}


- (void)testEncrypedUnHandled {
    XCTFail(@"TODO write test");
}


 - (void)testSendUnencrypted {
 XCTFail(@"TODO write test");
 }
 */

/*
 //msgpack not implemented
- (void)testBinaryAndText {
    XCTFail(@"TODO write test");
}

- (void)testBinary256 {
    XCTFail(@"TODO write test");
}

- (void)testTextAndBinary {
    XCTFail(@"TODO write test");
}

- (void)testPublishBinary {
    XCTFail(@"TODO write test");
}

*/
@end
