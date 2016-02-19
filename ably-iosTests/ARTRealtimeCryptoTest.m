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
#import "ARTRealtimeChannel.h"
#import "ARTTestUtil.h"
#import "ARTCrypto+Private.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"
#import "ARTChannelOptions.h"

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
    if (_realtime) {
        [ARTTestUtil removeAllChannels:_realtime];
        [_realtime.connection close];
    }
    _realtime = nil;
}

- (void)testSendEncodedMessage {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSendEncodedMessage"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        NSData * ivSpec = [[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0];
        NSData *keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
        ARTCipherParams *params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" key:keySpec keyLength:[keySpec length] iv:ivSpec];
        ARTRealtimeChannel *channel = [realtime.channels get:@"test" options:[[ARTChannelOptions alloc] initEncrypted:true cipherParams: params]];
        XCTAssert(channel);
        NSString *dataStr = @"someDataPayload";
        NSData *dataPayload = [dataStr  dataUsingEncoding:NSUTF8StringEncoding];
        NSString *stringPayload = @"someString";

        [channel publish:nil data:dataPayload cb:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel publish:nil data:stringPayload cb:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    XCTAssertFalse([result hasNext]);
                    NSArray *page = [result items];
                    XCTAssertTrue(page != nil);
                    XCTAssertEqual([page count], 2);
                    ARTMessage *stringMessage = [page objectAtIndex:0];
                    ARTMessage * dataMessage = [page objectAtIndex:1];
                    XCTAssertEqualObjects([dataMessage data], dataPayload);
                    XCTAssertEqualObjects([stringMessage data], stringPayload);
                    [exp fulfill];
                } error:nil];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSendEncodedMessageOnExistingChannel {
    XCTestExpectation *exp = [self expectationWithDescription:@"testSendEncodedMessageOnExistingChannel"];
    NSString *channelName = @"channelName";
    NSString *firstMessageText = @"firstMessage";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;

        ARTRealtimeChannel * channel = [realtime.channels get:channelName];
        [channel publish:nil data:firstMessageText cb:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            NSData * ivSpec = [[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0];
            NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
            ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" key:keySpec keyLength:[keySpec length] iv:ivSpec];
            ARTRealtimeChannel * c = [realtime.channels get:channelName options:[[ARTChannelOptions alloc] initEncrypted:true cipherParams:params]];
            XCTAssert(c);
            NSData * dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
            NSString * stringPayload = @"someString";
            [c publish:nil data:dataPayload cb:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                [c publish:nil data:stringPayload cb:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [c history:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        XCTAssertFalse([result hasNext]);
                        NSArray * page = [result items];
                        XCTAssertTrue(page != nil);
                        XCTAssertEqual([page count], 3);
                        ARTMessage * stringMessage = [page objectAtIndex:0];
                        ARTMessage * dataMessage = [page objectAtIndex:1];
                        ARTMessage * firstMessage = [page objectAtIndex:2];
                        XCTAssertEqualObjects([dataMessage data], dataPayload);
                        XCTAssertEqualObjects([stringMessage data], stringPayload);
                        XCTAssertEqualObjects([firstMessage data], firstMessageText);
                        [exp fulfill];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
