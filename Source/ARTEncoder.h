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

- (id)decode:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (NSData *)encode:(id)obj error:(NSError *_Nullable *_Nullable)error;


// TokenRequest
- (art_nullable NSData *)encodeTokenRequest:(ARTTokenRequest *)request error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTTokenRequest *)decodeTokenRequest:(NSData *)data error:(NSError * __autoreleasing *)error;

// TokenDetails
- (art_nullable NSData *)encodeTokenDetails:(ARTTokenDetails *)tokenDetails error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTTokenDetails *)decodeTokenDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// Message
- (art_nullable NSData *)encodeMessage:(ARTMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTMessage *)decodeMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// Message list
- (art_nullable NSData *)encodeMessages:(NSArray<ARTMessage *> *)messages error:(NSError *_Nullable *_Nullable)error;
- (art_nullable NSArray<ARTMessage *> *)decodeMessages:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// PresenceMessage
- (art_nullable NSData *)encodePresenceMessage:(ARTPresenceMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTPresenceMessage *)decodePresenceMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// PresenceMessage list
- (art_nullable NSData *)encodePresenceMessages:(NSArray<ARTPresenceMessage *> *)messages error:(NSError *_Nullable *_Nullable)error;
- (art_nullable NSArray<ARTPresenceMessage *> *)decodePresenceMessages:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// ProtocolMessage
- (art_nullable NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// DeviceDetails
- (art_nullable NSData *)encodeDeviceDetails:(ARTDeviceDetails *)deviceDetails error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTDeviceDetails *)decodeDeviceDetails:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (art_nullable NSArray<ARTDeviceDetails *> *)decodeDevicesDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// DevicePushDetails
- (art_nullable NSData *)encodeDevicePushDetails:(ARTDevicePushDetails *)devicePushDetails error:(NSError *_Nullable *_Nullable)error;
- (art_nullable ARTDevicePushDetails *)decodeDevicePushDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// Push Channel Subscription
- (art_nullable NSData *)encodePushChannelSubscription:(ARTPushChannelSubscription *)channelSubscription error:(NSError * __autoreleasing *)error;
- (art_nullable ARTPushChannelSubscription *)decodePushChannelSubscription:(NSData *)data error:(NSError * __autoreleasing *)error;
- (art_nullable NSArray<ARTPushChannelSubscription *> *)decodePushChannelSubscriptions:(NSData *)data error:(NSError * __autoreleasing *)error;

// Others
- (nullable NSDate *)decodeTime:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTErrorInfo *)decodeErrorInfo:(NSData *)error error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray *)decodeStats:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

@end

ART_ASSUME_NONNULL_END
