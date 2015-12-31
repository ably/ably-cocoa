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
@class ARTAuthTokenDetails;
@class ARTAuthTokenRequest;

typedef NS_ENUM(NSUInteger, ARTEncoderFormat) {
    ARTEncoderFormatJson,
    ARTEncoderFormatMsgPack
};

ART_ASSUME_NONNULL_BEGIN

@protocol ARTEncoder

- (NSString *)mimeType;
- (ARTEncoderFormat)format;
- (NSString *)formatAsString;

- (art_nullable NSData *)encodeTokenRequest:(ARTAuthTokenRequest *)request;

- (art_nullable ARTAuthTokenDetails *)decodeAccessToken:(NSData *)data error:(NSError * __autoreleasing *)error;
- (art_nullable ARTMessage *)decodeMessage:(NSData *)data;
- (art_nullable NSArray *)decodeMessages:(NSData *)data;
- (art_nullable NSData *)encodeMessage:(ARTMessage *)message;
- (art_nullable NSData *)encodeMessages:(NSArray *)messages;

- (art_nullable ARTPresenceMessage *)decodePresenceMessage:(NSData *)data;
- (art_nullable NSArray *)decodePresenceMessages:(NSData *)data;
- (art_nullable NSData *)encodePresenceMessage:(ARTPresenceMessage *)message;
- (art_nullable NSData *)encodePresenceMessages:(NSArray *)messages;

- (art_nullable NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message;
- (art_nullable ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data;

- (art_nullable NSDate *)decodeTime:(NSData *)data;
- (art_nullable NSError *)decodeError:(NSData *)error;
- (art_nullable NSArray *)decodeStats:(NSData *)data;

@end

ART_ASSUME_NONNULL_END
