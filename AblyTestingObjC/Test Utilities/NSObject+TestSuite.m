//

#import "NSObject+TestSuite.h"
#import "Aspects.h"

@implementation NSObject (TestSuite)

- (id<AspectToken>)testSuite_getReturnValueFrom:(SEL)selector callback:(void (^)(id))callback {
    return [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        __autoreleasing id result;
        [[info originalInvocation] getReturnValue:&result];
        callback([result copy]);
    } error:nil];
}

- (id<AspectToken>)testSuite_getArgumentFrom:(SEL)selector atIndex:(NSInteger)index callback:(void (^)(id))callback {
    return [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        __autoreleasing id arg;
        [[info originalInvocation] getArgument:&arg atIndex:2+index];
        callback(arg);
    } error:nil];
}

- (id<AspectToken>)testSuite_returnValueFor:(SEL)selector withDate:(NSDate *)value {
    return [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        NSDate *date = [value copy];
        CFRetain(CFAutorelease((__bridge CFTypeRef)(date)));
        [info.originalInvocation setReturnValue:&date];
    } error:nil];
}

- (id<AspectToken>)testSuite_injectIntoMethodBefore:(SEL)selector code:(void (^)(void))block {
    return [self aspect_hookSelector:selector withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info) {
        block();
    } error:nil];
}

- (id<AspectToken>)testSuite_injectIntoMethodAfter:(SEL)selector code:(void (^)(void))block {
    return [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        block();
    } error:nil];
}

- (id<AspectToken>)testSuite_replaceMethod:(SEL)selector code:(void (^)(void))block {
    return [self aspect_hookSelector:selector withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> info) {
        block();
    } error:nil];
}

@end

NSException * _Nullable tryInObjC(void(NS_NOESCAPE^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
