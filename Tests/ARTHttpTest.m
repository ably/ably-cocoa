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
#import "ARTTestUtil.h"

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

@end
