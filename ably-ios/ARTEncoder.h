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

ART_ASSUME_NONNULL_BEGIN

@protocol ARTEncoder

- (NSString *)mimeType;

- (NSData *)encodeTokenRequest:(ARTAuthTokenRequest *)request;

- (art_nullable ARTAuthTokenDetails *)decodeAccessToken:(NSData *)data error:(NSError * __autoreleasing *)error;
- (ARTMessage *)decodeMessage:(NSData *)data;
- (NSArray *)decodeMessages:(NSData *)data;
- (NSData *)encodeMessage:(ARTMessage *)message;
- (NSData *)encodeMessages:(NSArray *)messages;

- (ARTPresenceMessage *)decodePresenceMessage:(NSData *)data;
- (NSArray *)decodePresenceMessages:(NSData *)data;
- (NSData *)encodePresenceMessage:(ARTPresenceMessage *)message;
- (NSData *)encodePresenceMessages:(NSArray *)messages;

- (NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message;
- (ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data;

- (NSDate *)decodeTime:(NSData *)data;
- (NSError *)decodeError:(NSData *)error;
- (NSArray *)decodeStats:(NSData *)data;

@end

ART_ASSUME_NONNULL_END
