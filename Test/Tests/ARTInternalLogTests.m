#import <XCTest/XCTest.h>
#import "Ably_Tests-Swift.h"

/**
 This file exists for testing `ARTInternalLog`’s variadic methods, which are only accessible from Objective-C. The rest of this class’s functionality should be tested in `InternalLogTests.swift`.
 */
@interface ARTInternalLogTests : XCTestCase

@end

@implementation ARTInternalLogTests

- (void)test_verbose_vararg {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelVerbose;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog verbose:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelVerbose);
}

- (void)test_verbose_varargWithFileAndLine {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelVerbose;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog verbose:"foo.m" line:123 message:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"(foo.m:123) Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelVerbose);
}

- (void)test_debug_vararg {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelDebug;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog debug:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelDebug);
}

- (void)test_debug_varargWithFileAndLine {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelDebug;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog debug:"foo.m" line:123 message:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"(foo.m:123) Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelDebug);
}

- (void)test_info_vararg {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelInfo;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog info:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelInfo);
}

- (void)test_warn_vararg {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelWarn;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog warn:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelWarn);
}

- (void)test_error_vararg {
    ARTMockVersion2Log *const mock = [[ARTMockVersion2Log alloc] init];
    mock.logLevel = ARTLogLevelError;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithLogger:mock];

    [internalLog error:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelError);
}

@end
