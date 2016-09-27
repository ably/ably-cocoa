//
//  ARTRealtime+TestSuite.h
//  Ably
//
//  Created by Ricardo Pereira on 19/09/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ARTRealtime.h"

@interface ARTRealtime (TestSuite)

- (void)testSuite_waitForConnectionToClose:(XCTestCase *)textCase;

@end
