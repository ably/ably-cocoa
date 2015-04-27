//
//  ARTEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTMessage;
@class ARTPresenceMessage;
@class ARTProtocolMessage;
@class ARTTokenDetails;
@protocol ARTEncoder

- (NSString *)mimeType;



- (ARTTokenDetails *) decodeAccessToken:(NSData *) data;
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

- (NSArray *)decodeStats:(NSData *)data;

@end
