//
//  ARTHttpTest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ARTHttp.h"

@interface ARTHttpTest : XCTestCase

@property (readwrite, strong, nonatomic) ARTHttp *http;

@end

@implementation ARTHttpTest

- (void)setUp {
    [super setUp];
    self.http = [[ARTHttp alloc] init];
}

- (void)tearDown {
    self.http = nil;
    [super tearDown];
}

- (void)testNonExistantPath {
    XCTestExpectation *expectation = [self expectationWithDescription:@"get"];

    [self.http makeRequestWithMethod:@"GET" url:[NSURL URLWithString:@"http://rest.ably.io/non-existant-path"] headers:nil body:nil cb:^(ARTHttpResponse *response) {
        XCTAssert(response.status == 500);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}


@end
