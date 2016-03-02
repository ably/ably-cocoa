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
    [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        __autoreleasing id result;
        [[info originalInvocation] getReturnValue:&result];
        callback([result copy]);
    } error:nil];
}

- (void)testSuite_injectIntoMethod:(SEL)selector code:(void (^)(void))block {
    [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        block();
    } error:nil];
}

@end
