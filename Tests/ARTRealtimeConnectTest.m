//
//  ARTRealtimeConnectTest.m
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
#import "ARTRealtime+Private.h"
#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTEventEmitter.h"
#import "ARTRealtimeChannel.h"

@interface ARTRealtimeConnectTest : XCTestCase {
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeConnectTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    if (_realtime) {
        [ARTTestUtil removeAllChannels:_realtime];
        [_realtime resetEventEmitter];
        [_realtime close];
    }
    _realtime = nil;
}
- (void)testConnectText{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectText"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectPing {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectPing"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [realtime.connection ping:^(ARTErrorInfo *error) {
                    XCTAssertNil(error);
                    [expectation fulfill];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectStateChange {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.autoConnect = false;
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool connectingHappened = false;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnecting) {
                XCTAssertTrue(realtime.connection.id == nil);
                XCTAssertTrue(realtime.connection.key == nil);
                connectingHappened = true;
            }
            else if(state == ARTRealtimeConnected) {
                
                XCTAssertTrue(realtime.connection.id != nil);
                XCTAssertTrue(realtime.connection.key != nil);

                XCTAssertTrue(connectingHappened);
                [expectation fulfill];
            }
        }];
        [realtime connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}

- (void)testConnectStateChangeClose {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.autoConnect = false;
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool closingHappened = false;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if(state == ARTRealtimeConnected) {
                [realtime close];
            }
            else if(state == ARTRealtimeClosing) {
                closingHappened = true;
            }
            else if(state == ARTRealtimeClosed) {
                XCTAssertTrue(closingHappened);
                XCTAssertEqual([realtime.connection state], state);
                [expectation fulfill];
            }
        }];
        [realtime connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectionSerial {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.autoConnect = false;
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
        
            if(state == ARTRealtimeConnected) {
                XCTAssertEqual(realtime.connection.serial, -1);
                ARTRealtimeChannel * c =[realtime.channels get:@"chan"];
                [c publish:nil data:@"message" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertEqual(realtime.connection.serial, 0);
                    [c publish:nil data:@"message2" callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertEqual(realtime.connection.serial, 1);
                        [expectation fulfill];
                    }];
                    XCTAssertEqual(realtime.connection.serial, 0); //confirms that serial only updates after an ack
                }];
                [c attach];
            }
        }];
        [realtime connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}


- (void)testConnectAfterClose {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block int connectionCount=0;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
        
            if (state == ARTRealtimeConnected) {
                connectionCount++;
                if(connectionCount ==1) {
                    [realtime close];
                }
                else if( connectionCount ==2) {
                    [expectation fulfill];
                }
            }
            if( state == ARTRealtimeClosed && connectionCount ==1) {
                [realtime connect];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectingFromClosing {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool connectHappened = false;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
        
            if(state == ARTRealtimeConnected) {
                if(connectHappened) {
                    [expectation fulfill];
                }
                else {
                    connectHappened = true;
                    [realtime close];
                }
            }
            else if(state == ARTRealtimeClosed) {
                [realtime connect];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}

- (void)testConnectStates {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testConnectStates"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.autoConnect = false;
        ARTRealtime * realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        __block bool gotInitialized =false;
        __block bool gotConnecting =false;
        __block bool gotConnected =false;
        __block bool gotDisconnected =false;
        __block bool gotSuspended =false;
        __block bool gotClosing =false;
        __block bool gotClosed =false;
        __block bool gotFailed= false;
        
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;

            if(state == ARTRealtimeConnecting) {
                gotConnecting = true;
                if (stateChange.previous == ARTRealtimeInitialized) {
                    gotInitialized = true;
                }
            }
            else if(state == ARTRealtimeConnected) {
                if(!gotConnected) {
                    gotConnected = true;
                    [realtime close];
                }
                else {
                    [realtime onDisconnected];
                }
            }
            else if(state == ARTRealtimeDisconnected) {
                gotDisconnected = true;
                [realtime onSuspended];
            }
            else if(state == ARTRealtimeSuspended) {
                gotSuspended = true;
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else if(state == ARTRealtimeClosing) {
                gotClosing = true;
                
            }
            else if(state == ARTRealtimeClosed) {
                gotClosed = true;
                [realtime connect];
            }
            else if(state == ARTRealtimeFailed) {
                gotFailed = true;
                XCTAssertTrue(gotInitialized);
                XCTAssertTrue(gotConnecting);
                XCTAssertTrue(gotConnected);
                XCTAssertTrue(gotDisconnected);
                XCTAssertTrue(gotSuspended);
                XCTAssertTrue(gotClosing);
                XCTAssertTrue(gotClosed);
                XCTAssertTrue(gotFailed);
                XCTAssertTrue([realtime.connection state] == ARTRealtimeFailed);
                [exp fulfill];
            }
        }];
        [realtime connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectPingError {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testConnectPingError"];
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.autoConnect = false;
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool hasClosed = false;
        __block id listener = nil;
        listener = [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
        
            if(state == ARTRealtimeConnected) {
                [realtime close];
            }
            if(state == ARTRealtimeClosed) {
                hasClosed = true;
                XCTAssertThrows([realtime.connection ping:^(ARTErrorInfo *e) {}]);
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            if(state == ARTRealtimeFailed) {
                XCTAssertTrue(hasClosed);
                XCTAssertThrows([realtime.connection ping:^(ARTErrorInfo *e) {}]);
                [exp fulfill];
                [realtime.connection off:listener];
            }
        }];
        [realtime connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


@end
