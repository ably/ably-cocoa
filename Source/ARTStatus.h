//
//  ARTStatus.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

typedef NS_ENUM(NSUInteger, ARTState) {
    ARTStateOk = 0,
    ARTStateConnectionClosedByClient,
    ARTStateConnectionDisconnected,
    ARTStateConnectionSuspended,
    ARTStateConnectionFailed,
    ARTStateAccessRefused,
    ARTStateNeverConnected,
    ARTStateConnectionTimedOut,
    ARTStateAttachTimedOut,
    ARTStateDetachTimedOut,
    ARTStateNotAttached,
    ARTStateInvalidArgs,
    ARTStateCryptoBadPadding,
    ARTStateNoClientId,
    ARTStateMismatchedClientId,
    ARTStateRequestTokenFailed,
    ARTStateAuthUrlIncompatibleContent,
    ARTStateBadConnectionState,
    ARTStateError = 99999
};

/**
 ARTCodeErrors

 The list of all public error codes returned under the error domain ARTAblyErrorDomain
 */
typedef CF_ENUM(NSUInteger, ARTCodeError) {
    // FIXME: check hard coded errors
    ARTCodeErrorAPIKeyMissing = 80001
};

ART_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const ARTAblyErrorDomain;

@interface ARTErrorInfo : NSError

@property (readonly, getter=getMessage) NSString *message;
@property (readonly, getter=getStatus) NSInteger statusCode;

+ (ARTErrorInfo *)createWithCode:(NSInteger)code message:(NSString *)message;
+ (ARTErrorInfo *)createWithCode:(NSInteger)code status:(NSInteger)status message:(NSString *)message;
// FIXME: base NSError
+ (ARTErrorInfo *)createWithNSError:(NSError *)error;
+ (ARTErrorInfo *)wrap:(ARTErrorInfo *)error prepend:(NSString *)prepend;

- (NSString *)description;

@end


@interface ARTStatus : NSObject

@property (art_nullable, readonly, strong, nonatomic) ARTErrorInfo *errorInfo;
@property (nonatomic, assign) ARTState state;

+ (ARTStatus *)state:(ARTState) state;
+ (ARTStatus *)state:(ARTState) state info:(art_nullable ARTErrorInfo *) info;

- (NSString *)description;

@end

ART_ASSUME_NONNULL_END
