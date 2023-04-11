#import <XCTest/XCTest.h>
#import "Ably_Tests-Swift.h"

/**
 This file is written in Objective-C because it tests `ARTInternalLog`’s variadic methods, which are not accessible from Swift.
 */
@interface ARTInternalLogTests : XCTestCase

@end

@implementation ARTInternalLogTests

- (void)test_verbose_vararg {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelVerbose;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog verbose:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelVerbose);
}

- (void)test_verbose_varargWithFileAndLine {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelVerbose;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog verbose:"foo.m" line:123 message:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"(foo.m:123) Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelVerbose);
}

- (void)test_debug_vararg {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelDebug;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog debug:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelDebug);
}

- (void)test_debug_varargWithFileAndLine {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelDebug;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog debug:"foo.m" line:123 message:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"(foo.m:123) Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelDebug);
}

- (void)test_info_vararg {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelInfo;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog info:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelInfo);
}

- (void)test_warn_vararg {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelWarn;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog warn:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelWarn);
}

- (void)test_error_vararg {
    ARTMockInternalLogBackend *const mock = [[ARTMockInternalLogBackend alloc] init];
    mock.logLevel = ARTLogLevelError;
    ARTInternalLog *const internalLog = [[ARTInternalLog alloc] initWithBackend:mock];

    [internalLog error:@"Hello %@", @"there"];

    XCTAssertEqualObjects(mock.lastReceivedLogMessageArgumentMessage, @"Hello there");
    XCTAssertEqual(mock.lastReceivedLogMessageArgumentLevel, ARTLogLevelError);
}

@end
