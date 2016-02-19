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

@interface ARTCipherParams ()

@property (nonatomic, weak) ARTLog *logger;

@end

@protocol ARTChannelCipher

- (ARTStatus *)encrypt:(NSData *)plaintext output:(NSData **)output;
- (ARTStatus *)decrypt:(NSData *)ciphertext output:(NSData **)output;
- (NSString *)cipherName;
- (size_t) keyLength;

@end

@interface ARTCrypto ()

+ (NSString *)defaultAlgorithm;
+ (int)defaultKeyLength;
+ (int)defaultBlockLength;

+ (NSData *)generateRandomData:(size_t)length;
+ (NSData *)generateSecureRandomData:(size_t)length;

+ (id<ARTChannelCipher>)cipherWithParams:(ARTCipherParams *)params;

@end

#endif /* ARTCrypto_Private_h */
