//
//  NSError+ARTUtils.m
//  Ably
//
//  Created by Łukasz Szyszkowski on 05/07/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import "ARTNSError+ARTUtils.h"
#import "ARTStatus.h"

@implementation NSError (ARTUtils)

+ (nullable NSError *)copyFromError:(NSError *)error withRequestId:(nullable NSString *)requestId {
    if (error == nil) {
        return nil;
    }
    
    NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
    mutableInfo[ARTErrorInfoRequestIdKey] = requestId;
    
    return [NSError errorWithDomain:error.domain code:error.code userInfo:mutableInfo];
}

- (NSString *)requestId {
    return self.userInfo[ARTErrorInfoRequestIdKey];
}

@end
