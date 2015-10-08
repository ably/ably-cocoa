//
//  ARTCrypto.h
//  ably-ios
//
//  Created by Jason Choy on 20/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"
#import "ARTStatus.h"

@class ARTLog;

@interface ARTIvParameterSpec : NSObject
@property (nonatomic, weak) ARTLog * logger;
@property (readonly, nonatomic) NSData *iv;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithIv:(NSData *)iv;
+ (instancetype)ivSpecWithIv:(NSData *)iv;

@end

@interface ARTCipherParams : NSObject
@property (nonatomic, weak) ARTLog *logger;
@property (readonly, strong, nonatomic) NSString *algorithm;
@property (readonly, strong, nonatomic) NSData *keySpec;
@property (readonly, strong, nonatomic) ARTIvParameterSpec *ivSpec;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAlgorithm:(NSString *)algorithm keySpec:(NSData *)keySpec ivSpec:(ARTIvParameterSpec *)ivSpec;
+ (instancetype)cipherParamsWithAlgorithm:(NSString *)algorithm keySpec:(NSData *)keySpec ivSpec:(ARTIvParameterSpec *)ivSpec;

@end

@protocol ARTChannelCipher

- (ARTStatus *)encrypt:(NSData *)plaintext output:(NSData **)output;
- (ARTStatus *)decrypt:(NSData *)ciphertext output:(NSData **)output;
- (NSString *)cipherName;
- (size_t) keyLength;


@end

@interface ARTCrypto : NSObject

+ (NSString *)defaultAlgorithm;
+ (int)defaultKeyLength;
+ (int)defaultBlockLength;

+ (NSData *)generateRandomData:(size_t)length;
+ (NSData *)generateSecureRandomData:(size_t)length;

+ (ARTCipherParams *)defaultParams;
+ (ARTCipherParams *)defaultParamsWithKey:(NSData *)key;
+ (ARTCipherParams *)defaultParamsWithKey:(NSData *)key iv:(NSData *)iv;
+ (id<ARTChannelCipher>)cipherWithParams:(ARTCipherParams *)params;

@end
