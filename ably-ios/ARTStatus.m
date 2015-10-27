//
//  ARTStatus.m
//  ably
//
//  Created by vic on 26/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTStatus.h"

NSString *const ARTAblyErrorDomain = @"ARTAblyErrorDomain";

@implementation ARTErrorInfo

- (ARTErrorInfo *)setCode:(int)code message:(NSString *)message {
    _code = code;
    _statusCode = code / 100;
    _message = message;
    return self;
}

- (ARTErrorInfo *)setCode:(int)code status:(int)status message:(NSString *)message {
    _code = code;
    _statusCode = status;
    _message = message;
    return self;
}

+ (ARTErrorInfo *)createWithCode:(int)code message:(NSString *)message {
    return [[[ARTErrorInfo alloc] init] setCode:code message:message];
}

+ (ARTErrorInfo *)createWithCode:(int)code status:(int)status message:(NSString *)message {
    return [[[ARTErrorInfo alloc] init] setCode:code status:status message:message];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ARTErrorInfo with code %d, message: %@", self.statusCode, self.message];
}

@end

@implementation ARTStatus

- (instancetype)init {
    self = [super init];
    if(self) {
        _state = ARTStateOk;
        _errorInfo =[[ARTErrorInfo alloc] init];
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