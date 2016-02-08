//
//  NSObject+TestSuite.m
//  ably
//
//  Created by Ricardo Pereira on 08/02/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "NSObject+TestSuite.h"
#import <Aspects/Aspects.h>

@implementation NSObject (TestSuite)

- (void)testSuite_getReturnValueFrom:(SEL)selector callback:(void (^)(id))callback {
    [self aspect_hookSelector:selector withOptions:0 usingBlock:^(id<AspectInfo> info) {
        __autoreleasing id result;
        [[info originalInvocation] getReturnValue:&result];
        callback([result copy]);
    } error:nil];
}

@end
