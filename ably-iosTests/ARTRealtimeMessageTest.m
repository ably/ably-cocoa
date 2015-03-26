//
//  ARTRealtimeMessageTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"

@interface ARTRealtimeMessageTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end

@implementation ARTRealtimeMessageTest


- (void)setUp {
    
    [super setUp];
    
}

- (void)tearDown {
    _realtime = nil;
    _realtime2 = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}
- (void)withRealtime2:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime2) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime2);
        }];
        return;
    }
    cb(_realtime2);
}

- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay {
    __block int numReceived = 0;
    
    XCTestExpectation *e = [self expectationWithDescription:@"realtime"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
    [self withRealtime:^(ARTRealtime *realtime) {
        XCTestExpectation *expectation = [self expectationWithDescription:@"multiple_send"];
        ARTRealtimeChannel *channel = [realtime channel:name];
        
        [channel attach];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [channel subscribe:^(ARTMessage *message) {
                    ++numReceived;
                    if (numReceived == count) {
                        [expectation fulfill];
                    }
                }];
                
                [ARTTestUtil repeat:count delay:(delay / 1000.0) block:^(int i) {
                    NSString *msg = [NSString stringWithFormat:@"Test message (_multiple_send) %d", i];
                    [channel publish:msg withName:@"test_event" cb:^(ARTStatus status) {
                        
                    }];
                }];
            }
        }];
        [self waitForExpectationsWithTimeout:((delay / 1000.0) * count * 2) handler:nil];
    }];
    
    XCTAssertEqual(numReceived, count);
}

- (void)testSingleSendText {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendText"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"testSingleSendText"];
        [channel subscribe:^(ARTMessage * message) {
            XCTAssertEqualObjects([message content], @"testString");
            [expectation fulfill];
        }];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(ARTStatusOk, status);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testSingleSendEchoText {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendEchoText"];
    NSString * channelName = @"testSingleEcho";
    [self withRealtime:^(ARTRealtime *realtime1) {
        ARTRealtimeChannel *channel = [realtime1 channel:channelName];
            [channel subscribe:^(ARTMessage * message) {
                XCTAssertEqualObjects([message content], @"testStringEcho");
                NSLog(@"recieved testStringEcho!!");
                [expectation fulfill];
            }];
        [self withRealtime2:^(ARTRealtime *realtime2) {
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            [channel2 subscribe:^(ARTMessage * message) {
                XCTAssertEqualObjects([message content], @"testStringEcho");
            }];
            [channel2 publish:@"testStringEcho" cb:^(ARTStatus status) {
                XCTAssertEqual(ARTStatusOk, status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



- (void)testPublish_10_1000 {
    [self multipleSendName:@"multiple_send_10_1000" count:10 delay:1000];
}

- (void)testPublish_20_200 {
    [self multipleSendName:@"multiple_send_20_200" count:20 delay:200];
}

- (void)testMultipleText_1000_10 {
    [self multipleSendName:@"multiple_send_1000_10" count:1000 delay:10];
}

/*
//msgpack not implemented yet
- (void)testMultipleBinary_2000_5 {
    XCTFail(@"TODO write test");
}

- (void)testMultipleBinary_1000_1 {
    XCTFail(@"TODO write test");
}
- (void)testMultipleBinary_1000_2 {
    XCTFail(@"TODO write test");
}

- (void)testMultipleBinary_1000_20_5 {
    XCTFail(@"TODO write test");
}

- (void)testSingleErrorBinary {
    XCTFail(@"TODO write test");
}

- (void)testSingleSendBinary {
    XCTFail(@"TODO write test");
}

- (void)testMultipleBinary_200_50 {
    XCTFail(@"TODO write test");
}

- (void)testMultipleBinary_20_200 {
    XCTFail(@"TODO write test");
}

- (void)testMultipleBinary_10_1000 {
    XCTFail(@"TODO write test");
}

- (void)testSingleSendEchoBinary {
    XCTFail(@"TODO write test");
}
 */
@end
