//
//  ARTStatus.m
//  ably
//
//  Created by vic on 26/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTStatus.h"


@implementation ARTErrorInfo
-(void) setCode:(int) code message:(NSString *) message {
    _code = code;
    _statusCode = code / 100;
    _message = message;
}

-(void) setCode:(int) code status:(int) status message:(NSString *) message {
    _code = code;
    _statusCode = status;
    _message =message;
}

@end

@implementation ARTStatus

-(instancetype) init {
    self = [super init];
    if(self) {
        _status = ARTStatusOk;
        _errorInfo =[[ARTErrorInfo alloc] init];
   }
    return self;
}

-(void) setStatus:(ARTState)status {
    _status = status;
}

+(ARTStatus *) state:(ARTState) state {
    ARTStatus *s = [[ARTStatus alloc] init];
    s.status= state;
    return s;
}

+(ARTStatus *) state:(ARTState) state info:(ARTErrorInfo *) info {
    ARTStatus * s = [ARTStatus state:state];
    s.errorInfo = info;
    return s;
}

#pragma mark private

-(void) setErrorInfo:(ARTErrorInfo *)errorInfo {
    _errorInfo = errorInfo;
}

@end