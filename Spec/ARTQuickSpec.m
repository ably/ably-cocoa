//
//  ARTQuickSpec.m
//  Ably-iOS-Tests
//
//  Created by Lawrence Forooghian on 23/11/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import "ARTQuickSpec.h"

@implementation ARTQuickSpec

+ (NSArray<NSInvocation *> *)testInvocations {
    NSArray<NSInvocation *> *const result = super.testInvocations;
    NSLog(@"testInvocations is:");
    for (NSInvocation *const invocation in result) {
        puts([NSStringFromSelector(invocation.selector) cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return result;
}

@end
