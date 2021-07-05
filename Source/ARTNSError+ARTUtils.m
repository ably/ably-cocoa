//
//  NSError+ARTUtils.m
//  Ably
//
//  Created by Łukasz Szyszkowski on 05/07/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import "ARTNSError+ARTUtils.h"

@implementation NSError (ARTUtils)

- (NSError *)errorWithRequestId:(NSString *)requestId {
    if (requestId == nil) {
        return self;
    }
    
    NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    mutableInfo[@"request_id"] = requestId;
    
    return [NSError errorWithDomain:self.domain code:self.code userInfo:mutableInfo];
}

- (NSString *)requestId {
    return self.userInfo[@"request_id"];
}

@end
