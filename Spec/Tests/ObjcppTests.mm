//

/*
 This file is needed to check if C++ compiler is able to work with Ably Cocoa.
 */

#import <XCTest/XCTest.h>
#import <Ably/Ably.h>

class AblyVersionTestWrapper {

public:
    static void printVersionInfo();
};

void AblyVersionTestWrapper::printVersionInfo() {
    printf("Library accessed in c++ method: %s\r\n", ARTDefault.libraryVersion.UTF8String);
};


@interface ObjcppTests : XCTestCase
@end

@implementation ObjcppTests

- (void)testPrintVersionInfo {
    AblyVersionTestWrapper::printVersionInfo();
}

@end
