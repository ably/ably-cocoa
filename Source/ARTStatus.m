//
//  ARTStatus.m
//  ably
//
//  Created by vic on 26/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTStatus.h"

// Reverse-DNS style domain
NSString *const ARTAblyErrorDomain = @"io.ably.cocoa";

NSInteger getStatusFromCode(NSInteger code) {
    return code / 100;
}

@implementation ARTErrorInfo

+ (ARTErrorInfo *)createWithCode:(NSInteger)code message:(NSString *)message {
    return [ARTErrorInfo createWithCode:code status:getStatusFromCode(code) message:message];
}

+ (ARTErrorInfo *)createWithCode:(NSInteger)code status:(NSInteger)status message:(NSString *)message {
    return [[super alloc] initWithDomain:ARTAblyErrorDomain code:code userInfo:@{@"status": [NSNumber numberWithInteger:status], NSLocalizedDescriptionKey:message}];
}

+ (ARTErrorInfo *)createWithNSError:(NSError *)error {
    if ([error isKindOfClass:[ARTErrorInfo class]]) {
        return (ARTErrorInfo *)error;
    }
    return [ARTErrorInfo createWithCode:error.code message:error.description];
}

+ (ARTErrorInfo *)wrap:(ARTErrorInfo *)error prepend:(NSString *)prepend {
    return [ARTErrorInfo createWithCode:error.code status:error.statusCode message:[NSString stringWithFormat:@"%@%@", prepend, error.message]];
}

- (NSString *)getMessage {
    return (NSString *)self.userInfo[NSLocalizedDescriptionKey];
}

- (NSInteger)getStatus {
    return [(NSNumber *)self.userInfo[@"status"] integerValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ARTErrorInfo with code %ld, message: %@", (long)self.statusCode, self.message];
}

@end

@implementation ARTStatus

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = ARTStateOk;
        _errorInfo = nil;
   }
    return self;
}

+ (ARTStatus *)state:(ARTState)state {
    ARTStatus *s = [[ARTStatus alloc] init];
    s.state = state;
    return s;
}

+ (ARTStatus *)state:(ARTState)state info:(ARTErrorInfo *)info {
    ARTStatus * s = [ARTStatus state:state];
    s.errorInfo = info;
    return s;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ARTStatus: %lu, Error info: %@", (unsigned long)self.state, [self.errorInfo description]];
}


#pragma mark private

-(void) setErrorInfo:(ARTErrorInfo *)errorInfo {
    _errorInfo = errorInfo;
}

@end