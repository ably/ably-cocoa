//
//  ARTStatus.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ARTStatus) {
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
    ARTStatusError = 99999
};