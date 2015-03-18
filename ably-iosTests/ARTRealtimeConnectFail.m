//
//  ARTRealtimeConnectFail.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface ARTRealtimeConnectFail : XCTestCase

@end

@implementation ARTRealtimeConnectFail

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNotFoundErr {
    XCTFail(@"TODO write test");
}
- (void)testAuthErr {
    XCTFail(@"TODO write test");
}

- (void)testDisonnectFail {
    XCTFail(@"TODO write test");
}

- (void)testSuspendedFail {
    XCTFail(@"TODO write test");
}
- (void)testTokenExpireFail {
    XCTFail(@"TODO write test");
}
- (void)testInvalidRecoverFail {
    XCTFail(@"TODO write test");
}
- (void)testUnknownRecoverFail {
    XCTFail(@"TODO write test");
}



@end
