//
//  ARTEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTTypes.h"

@class ARTMessage;
@class ARTPresenceMessage;
@class ARTProtocolMessage;
@class ARTTokenDetails;
@class ARTTokenRequest;
@class ARTDeviceDetails;
@class ARTDevicePushDetails;
@class ARTPushChannelSubscription;

@protocol ARTPushRecipient;

typedef NS_ENUM(NSUInteger, ARTEncoderFormat) {
    ARTEncoderFormatJson,
    ARTEncoderFormatMsgPack
};

ART_ASSUME_NONNULL_BEGIN

@protocol ARTEncoder

- (NSString *)mimeType;
- (ARTEncoderFormat)format;
- (NSString *)formatAsString;

- (id)decode:(NSData *)data;
- (NSData *)encode:(id)obj;


// TokenRequest
- (art_nullable NSData *)encodeTokenRequest:(ARTTokenRequest *)request;
- (art_nullable ARTTokenRequest *)decodeTokenRequest:(NSData *)data error:(NSError * __autoreleasing *)error;

// TokenDetails
- (art_nullable NSData *)encodeTokenDetails:(ARTTokenDetails *)tokenDetails;
- (art_nullable ARTTokenDetails *)decodeTokenDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// Message
- (art_nullable NSData *)encodeMessage:(ARTMessage *)message;
- (art_nullable ARTMessage *)decodeMessage:(NSData *)data;

// Message list
- (art_nullable NSData *)encodeMessages:(NSArray *)messages;
- (art_nullable NSArray<ARTMessage *> *)decodeMessages:(NSData *)data;

// PresenceMessage
- (art_nullable NSData *)encodePresenceMessage:(ARTPresenceMessage *)message;
- (art_nullable ARTPresenceMessage *)decodePresenceMessage:(NSData *)data;

// PresenceMessage list
- (art_nullable NSData *)encodePresenceMessages:(NSArray *)messages;
- (art_nullable NSArray<ARTPresenceMessage *> *)decodePresenceMessages:(NSData *)data;

// ProtocolMessage
- (art_nullable NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message;
- (art_nullable ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data;

// DeviceDetails
- (art_nullable NSData *)encodeDeviceDetails:(ARTDeviceDetails *)deviceDetails;
- (art_nullable ARTDeviceDetails *)decodeDeviceDetails:(NSData *)data;

// DevicePushDetails
- (art_nullable NSData *)encodeDevicePushDetails:(ARTDevicePushDetails *)devicePushDetails;

// Push Channel Subscriptions
- (art_nullable NSArray<ARTPushChannelSubscription *> *)decodePushChannelSubscriptions:(NSData *)data error:(NSError * __autoreleasing *)error;

// Others
- (art_nullable NSDate *)decodeTime:(NSData *)data;
- (art_nullable NSError *)decodeError:(NSData *)error;
- (art_nullable NSArray *)decodeStats:(NSData *)data;

@end

ART_ASSUME_NONNULL_END
