//
//  ARTLogTest.m
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ARTLog.h"



@interface ARTLogTest : XCTestCase
@end

@implementation ARTLogTest

-(void) setUp {
    
}

-(void) tearDown {
    ARTLog * l = [[ARTLog alloc] init];
    [l setLogLevel:ARTLogLevelWarn];
}

- (void)testLogLevelToError {
    __block id lastLogged =nil;
    __block int logCount =0;
    ARTLog * l = [[ARTLog alloc] init];

    [l setLogLevel:ARTLogLevelError];
    
    [l verbose:@"v"];
    [l debug:@"d"];
    [l info:@"i"];
    [l warn:@"w"];
    XCTAssertEqual(logCount, 0);
    [l error:@"e"];
    XCTAssertEqual(logCount, 1);
    XCTAssertEqualObjects(lastLogged, @"ERROR: e");
}

-(void) testLogLevel {
    __block id lastLogged =nil;
    __block int logCount =0;
    ARTLog * l = [[ARTLog alloc] init];
    [l setLogLevel:ARTLogLevelDebug];
    [l verbose:@"v"];
    [l debug:@"d"];
    XCTAssertEqualObjects(lastLogged, @"DEBUG: d");
    [l info:@"i"];
    [l warn:@"w"];
    [l error:@"e"];
    XCTAssertEqual(logCount, 4);
    XCTAssertEqualObjects(lastLogged, @"ERROR: e");
}

-(void) testLogLevelNone {
    __block id lastLogged =nil;
    __block int logCount =0;
    ARTLog * l = [[ARTLog alloc] init];
    [l setLogLevel:ARTLogLevelNone];
    [l verbose:@"v"];
    [l debug:@"d"];
    [l info:@"i"];
    [l warn:@"w"];
    [l error:@"e"];
    XCTAssertEqual(logCount, 0);
    XCTAssertEqualObjects(lastLogged, nil);
}

-(void) testNoCrashWithoutCustomLogger {
    ARTLog * l = [[ARTLog alloc] init];
    [l setLogLevel:ARTLogLevelVerbose];
    [l verbose:@"v"];
    [l debug:@"d"];
    [l info:@"i"];
    [l warn:@"w"];
    [l error:@"e"];
}


@end
