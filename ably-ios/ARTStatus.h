//
//  ARTStatus.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ARTState) {
    ARTStatusOk = 0,
    ARTStatusConnectionClosedByClient,
    ARTStatusConnectionDisconnected,
    ARTStatusConnectionSuspended,
    ARTStatusConnectionFailed,
    ARTStatusAccessRefused,
    ARTStatusNeverConnected,
    ARTStatusConnectionTimedOut,
    ARTStatusNotAttached,
    ARTStatusInvalidArgs,
    ARTStatusCryptoBadPadding,
    ARTStatusNoClientId,
    ARTStatusError = 99999
};

@interface ARTErrorInfo : NSObject
@property (strong, nonatomic) NSString *message;
@property (assign, nonatomic) int statusCode;
@property (assign, nonatomic) int code;
@end

@interface ARTStatus : NSObject {
    
}
@property (readonly, strong, nonatomic) ARTErrorInfo * errorInfo;
@property (nonatomic, assign) ARTState status;

+(ARTStatus *) state:(ARTState) state;
+(ARTStatus *) state:(ARTState) state info:(ARTErrorInfo *) info;


@end
