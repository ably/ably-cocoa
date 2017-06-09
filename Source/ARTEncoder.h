//
//  ARTEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@class ARTMessage;
@class ARTPresenceMessage;
@class ARTProtocolMessage;
@class ARTTokenDetails;
@class ARTTokenRequest;

typedef NS_ENUM(NSUInteger, ARTEncoderFormat) {
    ARTEncoderFormatJson,
    ARTEncoderFormatMsgPack
};

ART_ASSUME_NONNULL_BEGIN

@protocol ARTEncoder

- (NSString *)mimeType;
- (ARTEncoderFormat)format;
- (NSString *)formatAsString;

- (nullable NSData *)encodeTokenRequest:(ARTTokenRequest *)request error:(NSError *_Nullable *_Nullable)error;
- (nullable NSData *)encodeTokenDetails:(ARTTokenDetails *)tokenDetails error:(NSError *_Nullable *_Nullable)error;

- (nullable ARTTokenDetails *)decodeTokenDetails:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTTokenRequest *)decodeTokenRequest:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTMessage *)decodeMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray *)decodeMessages:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable NSData *)encodeMessage:(ARTMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (nullable NSData *)encodeMessages:(NSArray *)messages error:(NSError *_Nullable *_Nullable)error;

- (nullable ARTPresenceMessage *)decodePresenceMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray *)decodePresenceMessages:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable NSData *)encodePresenceMessage:(ARTPresenceMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (nullable NSData *)encodePresenceMessages:(NSArray *)messages error:(NSError *_Nullable *_Nullable)error;

- (nullable NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

- (nullable NSDate *)decodeTime:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTErrorInfo *)decodeErrorInfo:(NSData *)error error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray *)decodeStats:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

@end

ART_ASSUME_NONNULL_END
