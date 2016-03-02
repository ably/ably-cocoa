//
//  ARTCrypto+Private.h
//  ably
//
//  Created by Toni Cárdenas on 19/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTCrypto_Private_h
#define ARTCrypto_Private_h

#import "ARTCrypto.h"
#import "ARTLog.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTCipherParams ()

@property (readonly, strong, nonatomic, art_nullable) NSData *iv;
@property (nonatomic, weak) ARTLog *logger;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key iv:(NSData *__art_nullable)iv;

@end

@protocol ARTChannelCipher

- (ARTStatus *)encrypt:(NSData *)plaintext output:(NSData *__art_nullable*__art_nullable)output;
- (ARTStatus *)decrypt:(NSData *)ciphertext output:(NSData *__art_nullable*__art_nullable)output;
- (NSString *)cipherName;
- (size_t) keyLength;

@end

@interface ARTCbcCipher : NSObject<ARTChannelCipher>

- (id)initWithCipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)cbcCipherWithParams:(ARTCipherParams *)cipherParams;


@property (nonatomic, weak) ARTLog * logger;
@property (readonly, strong, nonatomic) NSData *keySpec;
@property NSData *iv;
@property (readonly) NSUInteger blockLength;

@end

@interface ARTCrypto ()

+ (NSString *)defaultAlgorithm;
+ (int)defaultKeyLength;
+ (int)defaultBlockLength;

+ (NSData *)generateSecureRandomData:(size_t)length;

+ (id<ARTChannelCipher>)cipherWithParams:(ARTCipherParams *)params;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTCrypto_Private_h */
