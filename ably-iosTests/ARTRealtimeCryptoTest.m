//
//  ARTRealtimeCryptoTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTCrypto.h"

@interface ARTRealtimeCryptoTest : XCTestCase {
    ARTRealtime * _realtime;
}

@end

@implementation ARTRealtimeCryptoTest

- (void)setUp {
    [super setUp];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    _realtime = nil;
}

-(void) testSendEncodedMessage {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSendEncodedMessage"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTIvParameterSpec * ivSpec = [[ARTIvParameterSpec alloc] initWithIv:[[NSData alloc]
                                                                              initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
        NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
        ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" keySpec:keySpec ivSpec:ivSpec];
        ARTRealtimeChannel * c = [realtime channel:@"test" cipherParams:params];
        XCTAssert(c);
        NSString * dataStr = @"someDataPayload";
        NSData * dataPayload = [dataStr  dataUsingEncoding:NSUTF8StringEncoding];
        NSString * stringPayload = @"someString";
        [c publish:dataPayload cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [c publish:stringPayload cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [c history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    XCTAssertEqual(ARTStatusOk, status.status);
                    XCTAssertFalse([result hasNext]);
                    NSArray * page = [result currentItems];
                    XCTAssertTrue(page != nil);
                    XCTAssertEqual([page count], 2);
                    ARTMessage * stringMessage = [page objectAtIndex:0];
                    //ARTMessage * dataMessage = [page objectAtIndex:1];
                    //TODO work out why these arent equivalent
                    //XCTAssertEqualObjects([dataMessage content], dataPayload);
                    XCTAssertEqualObjects([stringMessage content], stringPayload);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testSendEncodedMessageOnExistingChannel {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSendEncodedMessageOnExistingChannel"];
    NSString * channelName = @"channelName";
    NSString * firstMessageText = @"firstMessage";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        
        ARTRealtimeChannel * channel = [realtime channel:channelName];
        [channel publish:firstMessageText cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            ARTIvParameterSpec * ivSpec = [[ARTIvParameterSpec alloc] initWithIv:[[NSData alloc]
                                                                                  initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
            NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
            ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" keySpec:keySpec ivSpec:ivSpec];
            ARTRealtimeChannel * c = [realtime channel:channelName cipherParams:params];
            XCTAssert(c);
            NSData * dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
            NSString * stringPayload = @"someString";
            [c publish:dataPayload cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [c publish:stringPayload cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [c history:^(ARTStatus *status, id<ARTPaginatedResult> result) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        XCTAssertEqual(ARTStatusOk, status.status);
                        XCTAssertFalse([result hasNext]);
                        NSArray * page = [result currentItems];
                        XCTAssertTrue(page != nil);
                        XCTAssertEqual([page count], 3);
                        ARTMessage * stringMessage = [page objectAtIndex:0];
                        ARTMessage * dataMessage = [page objectAtIndex:1];
                        ARTMessage * firstMessage = [page objectAtIndex:2];
                        XCTAssertEqualObjects([dataMessage content], dataPayload);
                        XCTAssertEqualObjects([stringMessage content], stringPayload);
                        XCTAssertEqualObjects([firstMessage content], firstMessageText);
                        [exp fulfill];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


//TODO implement
/*
- (void)testSingleSendText {
    XCTFail(@"TODO write test");
}

- (void)testSingleSendText256 {
    XCTFail(@"TODO write test");
}

- (void)testMultipleSendText_2_200 {
    XCTFail(@"TODO write test");
}

- (void)testMultipleSendText_20_100 {
    XCTFail(@"TODO write test");
}


- (void)testSingleKeyMismatch {
    XCTFail(@"TODO write test");
}



- (void)testEncryptedUnhandled {
    XCTFail(@"TODO write test");
}

- (void)testSetCipherParams {
    XCTFail(@"TODO write test");
}

- (void)testSingleUnencrypted {
    XCTFail(@"TODO write test");
}
 */

/*
 //msgpack not implemented yet.
- (void)testMultipleSendBinary_2_200 {
    XCTFail(@"TODO write test");
}
- (void)testMultipleSendBinary_20_100 {
    XCTFail(@"TODO write test");
}

- (void)testSingleBinaryText {
    XCTFail(@"TODO write test");
}

- (void)testSingleTextBinary {
    XCTFail(@"TODO write test");
}

- (void)testSingleSendBinary256 {
    XCTFail(@"TODO write test");
}
- (void)testSingleSendBinary{
    XCTFail(@"TODO write test");
}
*/


@end
