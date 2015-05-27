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
@end

@implementation ARTStatus

-(instancetype) initWithState:(ARTState) state {
    self = [super init];
    if(self) {
        NSLog(@"state is %d",(int) state);
        _status = state;
        _errorInfo = nil;
    }
    return self;
}

-(void) setStatus:(ARTState)status {
    NSLog(@"setting state to %d", status);
    _status = status;
}
+(ARTStatus *) state:(ARTState) state {
    return [[ARTStatus alloc] initWithState:state];
}
+(ARTStatus *) state:(ARTState) state info:(ARTErrorInfo *) info {
    ARTStatus * s = [[ARTStatus alloc] initWithState:state];
    s.errorInfo = info;
    return s;
}

#pragma mark private

-(void) setErrorInfo:(ARTErrorInfo *)errorInfo {
    _errorInfo = errorInfo;
}

@end