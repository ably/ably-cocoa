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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"

@interface ARTRealtimeConnectTest : XCTestCase {
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeConnectTest


- (void)setUp {
    [super setUp];
    [ARTLog setLogLevel:ArtLogLevelVerbose];
}

- (void)tearDown {
    [super tearDown];
    _realtime = nil;
}
- (void)testConnectText{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectText"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectPing {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectPing"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [realtime ping:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [expectation fulfill];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectStateChange {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool connectingHappened = false;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnecting) {
                XCTAssertEqual([realtime connectionId], nil);
                XCTAssertEqual([realtime connectionKey], nil);
                connectingHappened = true;
            }
            else if(state == ARTRealtimeConnected) {
                
                XCTAssertTrue([realtime connectionId] != nil);
                XCTAssertTrue([realtime connectionKey] != nil);

                XCTAssertTrue(connectingHappened);
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}

- (void)testConnectStateChangeClose {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool closingHappened = false;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime close];
            }
            else if(state == ARTRealtimeClosing) {
                closingHappened = true;
            }
            else if(state == ARTRealtimeClosed) {
                XCTAssertTrue(closingHappened);
                XCTAssertEqual([realtime state], state);
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectionSerial {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                XCTAssertEqual([realtime connectionSerial], -1);
                ARTRealtimeChannel * c =[realtime channel:@"chan"];
                [c publish:@"message" cb:^(ARTStatus *status) {
                    XCTAssertEqual([realtime connectionSerial], 0);
                    [c publish:@"message2" cb:^(ARTStatus *status) {
                        XCTAssertEqual([realtime connectionSerial], 1);
                        [expectation fulfill];
                    }];
                    XCTAssertEqual([realtime connectionSerial], 0); //confirms that serial only updates after an ack
                }];
                [c attach];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}


- (void)testConnectAfterClose {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block int connectionCount=0;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"testConnectStateChange"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool connectHappened = false;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                if(connectHappened) {
                    [expectation fulfill];
                }
                else {
                    connectHappened = true;
                    [realtime close];
                }
            }
            else if(state == ARTRealtimeClosing) {
                XCTAssertFalse([realtime connect]);
            }
            else if(state == ARTRealtimeClosed) {
                XCTAssertTrue([realtime connect]);
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}

- (void)testConnectStates {
    XCTestExpectation *exp = [self expectationWithDescription:@"testConnectStates"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.autoConnect = false;
        [ARTRealtime realtimeWithOptions:options cb:^(ARTRealtime *realtime) {
            _realtime = realtime;
            __block bool gotInitialized =false;
            __block bool gotConnecting =false;
            __block bool gotConnected =false;
            __block bool gotDisconnected =false;
            __block bool gotSuspended =false;
            __block bool gotClosing =false;
            __block bool gotClosed =false;
            __block bool gotFailed= false;
            
            [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                if(state == ARTRealtimeChannelInitialised) {
                    gotInitialized = true;
                    [realtime connect];
                }
                else if(state == ARTRealtimeConnecting) {
                    gotConnecting = true;
                    
                }
                else if(state == ARTRealtimeConnected) {
                    if(!gotConnected) {
                        gotConnected = true;
                        [realtime close];
                    }
                    else {
                        [realtime onDisconnected:nil];
                    }
                }
                else if(state == ARTRealtimeDisconnected) {
                    gotDisconnected = true;
                    [realtime onSuspended];
                }
                else if(state == ARTRealtimeSuspended) {
                    gotSuspended = true;
                    [realtime onError:nil];
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
                    XCTAssertTrue([realtime state] == ARTRealtimeFailed);
                    [exp fulfill];
                }
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectPingError {
    XCTestExpectation *exp = [self expectationWithDescription:@"testConnectPingError"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block bool hasClosed = false;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [realtime close];
            }
            if(state == ARTRealtimeClosed) {
                hasClosed = true;
                XCTAssertThrows([realtime ping:^(ARTStatus *s) {}]);
                [realtime onError:nil];
            }
            if(state == ARTRealtimeFailed) {
                XCTAssertTrue(hasClosed);
                XCTAssertThrows([realtime ping:^(ARTStatus *s) {}]);
                [exp fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


@end
