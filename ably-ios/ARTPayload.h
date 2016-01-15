//
//  ARTPayload.h
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTStatus.h"

@protocol ARTPayloadEncoder;

@class ARTCipherParams;

ART_ASSUME_NONNULL_BEGIN

@interface ARTPayload : NSObject

@property (art_nullable, readwrite, strong, nonatomic) id payload;
@property (readwrite, strong, nonatomic) NSString *encoding;

- (instancetype)init;
- (instancetype)initWithPayload:(art_nullable id)payload encoding:(NSString *)encoding;

+ (instancetype)payload;
+ (instancetype)payloadWithPayload:(art_nullable id)payload encoding:(NSString *)encoding;

+ (id<ARTPayloadEncoder>)defaultPayloadEncoder:(ARTCipherParams *)cipherParams;
+ (size_t)payloadArraySizeLimit;

@end

@interface NSString (ARTPayload)

- (NSString *)artAddEncoding:(NSString *)encoding;
- (NSString *)artLastEncoding;
- (NSString *)artRemoveLastEncoding;

@end

@protocol ARTPayloadEncoder

- (ARTStatus *)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing __art_nonnull *__art_nonnull)output;
- (ARTStatus *)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing __art_nonnull *__art_nonnull)output;
- (NSString *)name;

@end

@interface ARTBase64PayloadEncoder : NSObject <ARTPayloadEncoder>

+ (instancetype)instance;
+ (NSString *)toBase64:(NSData *) input;
+ (NSString *)fromBase64:(NSString *) base64;

@end

@interface ARTUtf8PayloadEncoder : NSObject <ARTPayloadEncoder>

+ (instancetype)instance;

@end

@interface ARTJsonPayloadEncoder : NSObject <ARTPayloadEncoder>

+ (instancetype)instance;

@end

@interface ARTCipherPayloadEncoder : NSObject <ARTPayloadEncoder>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCipherParams:(ARTCipherParams *)cipherParams;

@end

@interface ARTPayloadEncoderChain : NSObject <ARTPayloadEncoder>

- (instancetype)init;
- (instancetype)initWithEncoders:(NSArray *)encoders;

@end

ART_ASSUME_NONNULL_END
