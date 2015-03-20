//
//  ARTRealtimeChannelHistoryTest.m
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

@interface ARTRealtimeChannelHistoryTest : XCTestCase
{
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeChannelHistoryTest

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
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



- (void)testHistory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testHistoryBothChannels {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"historyBothChanels1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"historyBothChanels2"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        NSString * both = @"historyBoth";
        ARTRealtimeChannel *channel1 = [realtime channel:both];
        ARTRealtimeChannel *channel2 = [realtime channel:both];
        [channel1 publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel2 publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel1 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation1 fulfill];
                    
                }];
                [channel2 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation2 fulfill];
                    
                    
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testHistoryForward {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel historyWithParams:@{@"direction" : @"forwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



//TODO this test seems really pointless. Do we need
- (void)testHistoryWaitForPersistenceText {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                sleep(16);
                [channel historyWithParams:@{@"direction" : @"forwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryLimitForward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryLimitBackward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryTimeForward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryTimeBackward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryPaginateForward{
    XCTFail(@"TODO write test");
}
- (void)testHistoryPaginateBackward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryPaginateFirstForward{
    XCTFail(@"TODO write test");
}
- (void)testHistoryPaginateFirstBackward{
    XCTFail(@"TODO write test");
}
- (void)testHistoryFromAttach{
    XCTFail(@"TODO write test");
}


/* msgpack not implemented yet
 
-(void)testHistoryBinary {
    XCTFail(@"TODO write test");
}
- (void)testHistoryWaitBinaryBackward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryMixedBinaryFoward {
    XCTFail(@"TODO write test");
}
-(void)testHistoryWaitBinaryForward {
    XCTFail(@"TODO write test");
}
-(void)testHistoryTypesBinary {
    XCTFail(@"TODO write test");
}
-(void)testHistoryWaitBinary {
    XCTFail(@"TODO write test");
}
 */


@end
