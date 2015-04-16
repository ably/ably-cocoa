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
    [ARTLog setLogCallback:nil];
}

- (void)testLogLevelToError {
    // This is an example of a functional test case.
    
    __block id lastLogged =nil;
    __block int logCount =0;
    [ARTLog setLogCallback:^(id message){
        lastLogged = message;
        logCount++;
    }];
    
    [ARTLog setLogLevel:ArtLogLevelError];
    
    [ARTLog verbose:@"v"];
    [ARTLog debug:@"d"];
    [ARTLog info:@"i"];
    [ARTLog warn:@"w"];
    XCTAssertEqual(logCount, 0);
    [ARTLog error:@"e"];
    XCTAssertEqual(logCount, 1);
    XCTAssertEqualObjects(lastLogged, @"e");
}

-(void) testLogLevel {
    __block id lastLogged =nil;
    __block int logCount =0;
    [ARTLog setLogCallback:^(id message){
        lastLogged = message;
        logCount++;
    }];
    [ARTLog setLogLevel:ArtLogLevelDebug];
    [ARTLog verbose:@"v"];
    [ARTLog debug:@"d"];
    XCTAssertEqualObjects(lastLogged, @"d");
    [ARTLog info:@"i"];
    [ARTLog warn:@"w"];
    [ARTLog error:@"e"];
    XCTAssertEqual(logCount, 4);
    XCTAssertEqualObjects(lastLogged, @"e");
}

-(void) testLogLevelNone {
    __block id lastLogged =nil;
    __block int logCount =0;
    [ARTLog setLogCallback:^(id message){
        lastLogged = message;
        logCount++;
    }];
    [ARTLog setLogLevel:ArtLogLevelNone];
    [ARTLog verbose:@"v"];
    [ARTLog debug:@"d"];

    [ARTLog info:@"i"];
    [ARTLog warn:@"w"];
    [ARTLog error:@"e"];
    XCTAssertEqual(logCount, 0);
    XCTAssertEqualObjects(lastLogged, nil);
}

-(void) testNoCrashWithoutCustomLogger {
    [ARTLog setLogLevel:ArtLogLevelVerbose];
    [ARTLog verbose:@"v"];
    [ARTLog debug:@"d"];
    [ARTLog info:@"i"];
    [ARTLog warn:@"w"];
    [ARTLog error:@"e"];
}


@end
