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
    ARTStateNotAttached,
    ARTStateInvalidArgs,
    ARTStateCryptoBadPadding,
    ARTStateNoClientId,
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

@interface ARTErrorInfo : NSObject

@property (readonly, copy, nonatomic) NSString *message;
@property (readonly, assign, nonatomic) int statusCode;
@property (readonly, assign, nonatomic) int code;

// FIXME: use NSInteger instead int (don't know what kind of processor architecture your code might run)
- (ARTErrorInfo *)setCode:(NSInteger) code message:(NSString *) message;
- (ARTErrorInfo *)setCode:(NSInteger) code status:(NSInteger) status message:(NSString *) message;

+ (ARTErrorInfo *)createWithCode:(NSInteger)code message:(NSString *)message;
+ (ARTErrorInfo *)createWithCode:(NSInteger)code status:(NSInteger)status message:(NSString *)message;
// FIXME: base NSError
+ (ARTErrorInfo *)createWithNSError:(NSError *)error;

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
