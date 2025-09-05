#import "NSError+ARTUtils.h"
#import "ARTStatus.h"

@implementation NSError (ARTUtils)

+ (NSError *)copyFromError:(NSError *)error withRequestId:(nullable NSString *)requestId {
    NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
    mutableInfo[ARTErrorInfoRequestIdKey] = requestId;
    
    return [NSError errorWithDomain:error.domain code:error.code userInfo:mutableInfo];
}

- (NSString *)requestId {
    return self.userInfo[ARTErrorInfoRequestIdKey];
}

@end
