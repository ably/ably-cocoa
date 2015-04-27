//
//  ARTCrypto.m
//  ably-ios
//
//  Created by Jason Choy on 20/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTCrypto.h"

#import <CommonCrypto/CommonCrypto.h>

#import "ARTLog.h"

@interface ARTCipherParams ()

- (BOOL)ccAlgorithm:(CCAlgorithm *)algorithm;

@end

@interface ARTCrypto ()

@property (readonly, strong, nonatomic) ARTCipherParams *params;

@end

@interface ARTCbcCipher : NSObject<ARTChannelCipher>

- (id)initWithCipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)cbcCipherWithParams:(ARTCipherParams *)cipherParams;

@property (readonly) ARTSecretKeySpec *keySpec;
@property NSData *iv;
@property (readonly) NSUInteger blockLength;
@property CCAlgorithm algorithm;

@end

@implementation ARTSecretKeySpec

- (instancetype)initWithKey:(NSData *)key algorithm:(NSString *)algorithm {
    self = [super init];
    if (self) {
        _key = key;
        _algorithm = algorithm;
    }
    return self;
}

+ (instancetype)secretKeySpecWithKey:(NSData *)key algorithm:(NSString *)algorithm {
    return [[ARTSecretKeySpec alloc] initWithKey:key algorithm:algorithm];
}

@end

@implementation ARTIvParameterSpec

- (instancetype)initWithIv:(NSData *)iv {
    self = [super init];
    if (self) {
        _iv = iv;
    }
    return self;
}

+ (instancetype)ivSpecWithIv:(NSData *)iv {
    return [[ARTIvParameterSpec alloc] initWithIv:iv];
}

@end

@implementation ARTCipherParams

- (instancetype)initWithAlgorithm:(NSString *)algorithm keySpec:(ARTSecretKeySpec *)keySpec ivSpec:(ARTIvParameterSpec *)ivSpec {
    self = [super init];
    if (self) {
        _algorithm = algorithm;
        _keySpec = keySpec;
        _ivSpec = ivSpec;
    }
    return self;
}

+ (instancetype)cipherParamsWithAlgorithm:(NSString *)algorithm keySpec:(ARTSecretKeySpec *)keySpec ivSpec:(ARTIvParameterSpec *)ivSpec {
    return [[ARTCipherParams alloc] initWithAlgorithm:algorithm keySpec:keySpec ivSpec:ivSpec];
}

- (BOOL)ccAlgorithm:(CCAlgorithm *)algorithm {
    if (NSOrderedSame == [self.algorithm compare:@"AES" options:NSCaseInsensitiveSearch]) {
        if ([self.ivSpec.iv length] != 16) {
            [ARTLog error:[NSString stringWithFormat:@"ArtCrypto Error iv length is not 16: %d", (int)[self.ivSpec.iv length]]];
            return NO;
        }
        *algorithm = kCCAlgorithmAES128;
    } else if (NSOrderedSame == [self.algorithm compare:@"DES" options:NSCaseInsensitiveSearch]) {
        *algorithm = kCCAlgorithmDES;
    } else if (NSOrderedSame == [self.algorithm compare:@"3DES" options:NSCaseInsensitiveSearch]) {
        *algorithm = kCCAlgorithm3DES;
    } else if (NSOrderedSame == [self.algorithm compare:@"CAST" options:NSCaseInsensitiveSearch]) {
        *algorithm = kCCAlgorithmCAST;
    } else if (NSOrderedSame == [self.algorithm compare:@"RC4" options:NSCaseInsensitiveSearch]) {
        *algorithm = kCCAlgorithmRC4;
    } else if (NSOrderedSame == [self.algorithm compare:@"RC2" options:NSCaseInsensitiveSearch]) {
        *algorithm = kCCAlgorithmRC2;
    } else {
        return NO;
    }
    return YES;
}

@end

@implementation ARTCbcCipher

- (id)initWithCipherParams:(ARTCipherParams *)cipherParams {
    self = [super init];
    if (self) {
        _keySpec = cipherParams.keySpec;
        _iv = cipherParams.ivSpec.iv;
        _blockLength = [_iv length];

        if (![cipherParams ccAlgorithm:&_algorithm]) {
            return nil;
        }
    }
    return self;
}

-(size_t) keyLength {
    return [self.keySpec.key length] *8;
}

+ (instancetype)cbcCipherWithParams:(ARTCipherParams *)cipherParams {
    return [[self alloc] initWithCipherParams:cipherParams];
}



- (ARTStatus)encrypt:(NSData *)plaintext output:(NSData *__autoreleasing *)output {
    // Encryptions must be serialized as they depend on the final block of the previous iteration
    NSData *ciphertext = nil;

    // The maximum cipher text is plaintext length + block length. We are also prepending this with the IV so need 2 block lengths in addition to the plaintext length.
    size_t outputBufLen = [plaintext length] + self.blockLength * 2;
    void *buf = malloc(outputBufLen);

    if (!buf) {
        [ARTLog error:@"ARTCrypto error encrypting"];
        return ARTStatusError;
    }

    // Copy the iv first
    memcpy(buf, [self.iv bytes], self.blockLength);

    void *ciphertextBuf = ((char *)buf) + self.blockLength;
    size_t ciphertextBufLen = outputBufLen - self.blockLength;

    const void *key = [self.keySpec.key bytes];
    size_t keyLen = [self.keySpec.key length];

    const void *iv = [self.iv bytes];
    const void *dataIn = [plaintext bytes];
    size_t dataInLen = [plaintext length];

    size_t bytesWritten = 0;
    CCCryptorStatus status = CCCrypt(kCCEncrypt, self.algorithm, kCCOptionPKCS7Padding, key, keyLen, iv, dataIn, dataInLen, ciphertextBuf, ciphertextBufLen, &bytesWritten);

    if (status) {
        [ARTLog error:[NSString stringWithFormat:@"ARTCrypto error encrypting. Status is %d", status]];
        free(ciphertextBuf);
        return ARTStatusError;
    }

    ciphertext = [NSData dataWithBytesNoCopy:buf length:(bytesWritten + self.blockLength) freeWhenDone:YES];
    if (nil == ciphertext) {
        [ARTLog error:@"ARTCrypto error encrypting. cipher text is nil"];
        free(buf);
        return ARTStatusError;
    }

    // Finally update the iv. This should be the last *blockSize* bytes of the cipher text
    const void *newIvData = ((const uint8_t *)[ciphertext bytes]) + [ciphertext length] - self.blockLength;
    NSData *newIv = [NSData dataWithBytes:newIvData length:self.blockLength];
    if (newIv) {
        self.iv = newIv;
    } else {
        [ARTLog warn:@"ARTCrypto error encrypting. error updating iv"];
    }

    *output = ciphertext;

    return ARTStatusOk;
}

- (ARTStatus)decrypt:(NSData *)ciphertext output:(NSData *__autoreleasing *)output {
    // The first *blockLength* bytes are the iv
    if ([ciphertext length] < self.blockLength) {
        return ARTStatusInvalidArgs;
    }

    NSData *ivData = [ciphertext subdataWithRange:NSMakeRange(0, self.blockLength)];
    NSData *actualCiphertext = [ciphertext subdataWithRange:NSMakeRange(self.blockLength, [ciphertext length] - self.blockLength)];

    CCOptions options = 0;
    const void *key = [self.keySpec.key bytes];
    size_t keyLength = [self.keySpec.key length];

    const void *iv = [ivData bytes];
    const void *dataIn = [actualCiphertext bytes];
    size_t dataInLength = [actualCiphertext length];

    // The output will never be more than the input + block length
    size_t outputLength = dataInLength + self.blockLength;
    void *buf = malloc(outputLength);
    size_t bytesWritten = 0;

    if (!buf) {
        [ARTLog error:@"ARTCrypto error decrypting."];
        return ARTStatusError;
    }

    // Decrypt without padding because CCCrypt does not return an error code
    // if the decrypted value is not padded correctly
    CCCryptorStatus status = CCCrypt(kCCDecrypt, self.algorithm, options, key, keyLength, iv, dataIn, dataInLength, buf, outputLength, &bytesWritten);

    if (status) {
        [ARTLog error:[NSString stringWithFormat:@"ARTCrypto error decrypting. Status is %d", status]];
        free(buf);
        return ARTStatusError;
    }

    // Check that the decrypted value is padded correctly and determine the unpadded length
    const char *cbuf = (char *)buf;
    int paddingLength = cbuf[bytesWritten - 1];

    if (0 == paddingLength || paddingLength > bytesWritten) {            free(buf);
        return ARTStatusCryptoBadPadding;
    }

    for (size_t i=(bytesWritten - 1); i>(bytesWritten - paddingLength); --i) {
        if (paddingLength != cbuf[i-1]) {
            free(buf);
            return ARTStatusCryptoBadPadding;
        }
    }

    size_t unpaddedLength = bytesWritten - paddingLength;

    NSData *plaintext = [NSData dataWithBytesNoCopy:buf length:unpaddedLength freeWhenDone:YES];
    if (!plaintext) {
        [ARTLog error:@"ARTCrypto error decrypting. plain text is nil"];
        free(buf);
    }

    *output = plaintext;

    return ARTStatusOk;
}

- (NSString *)cipherName {
    NSString *algo = nil;
    switch (self.algorithm) {
        case kCCAlgorithmAES128:
            algo = @"aes-128";
            break;

        case kCCAlgorithmDES:
            algo = @"des";
            break;
        case kCCAlgorithm3DES:
            algo = @"3des";
            break;
        case kCCAlgorithmCAST:
            algo = @"cast";
            break;
        case kCCAlgorithmRC4:
            algo = @"rc4";
            break;
        case kCCAlgorithmRC2:
            algo = @"rc2";
            break;
        default:
            NSAssert(NO, @"Invalid algorithm");
            return nil;
    }
    return [NSString stringWithFormat:@"%@-cbc", algo];
}

@end

@implementation ARTCrypto

+ (NSString *)defaultAlgorithm {
    return @"AES";
}

+ (int)defaultKeyLength {
    return 16;
}

+ (int)defaultBlockLength {
    return 16;
}

+ (NSData *)generateRandomData:(size_t)length {
    void *buf = malloc(length);
    if (!buf) {
        return nil;
    }
    arc4random_buf(buf, length);
    NSData *outputData = [NSData dataWithBytesNoCopy:buf length:length freeWhenDone:YES];
    if (!outputData) {
        free(buf);
    }
    return outputData;
}

+ (NSData *)generateSecureRandomData:(size_t)length {
    void *buf = malloc(length);
    if (!buf) {
        return nil;
    }
    int rc = SecRandomCopyBytes(kSecRandomDefault, length, buf);
    if (rc != 0) {
        free(buf);
        return nil;
    }

    NSData *outputData = [NSData dataWithBytesNoCopy:buf length:length freeWhenDone:YES];
    if (!outputData) {
        free(buf);
    }
    return outputData;
}

+ (ARTCipherParams *)defaultParams {
    NSData *key = [self generateSecureRandomData:[self defaultKeyLength]];
    if (nil == key) {
        return nil;
    }
    return [self defaultParamsWithKey:key];
}

+ (ARTCipherParams *)defaultParamsWithKey:(NSData *)key {
    NSData *ivData = [self generateSecureRandomData:[self defaultBlockLength]];
    if (nil == ivData) {
        return nil;
    }
    return [self defaultParamsWithKey:key iv:ivData];
}

+ (ARTCipherParams *)defaultParamsWithKey:(NSData *)key iv:(NSData *)iv {
    ARTSecretKeySpec *keySpec = [ARTSecretKeySpec secretKeySpecWithKey:key algorithm:[self defaultAlgorithm]];

    ARTIvParameterSpec *ivSpec = [ARTIvParameterSpec ivSpecWithIv:iv];

    return [ARTCipherParams cipherParamsWithAlgorithm:[self defaultAlgorithm] keySpec:keySpec ivSpec:ivSpec];
}

+ (id<ARTChannelCipher>)cipherWithParams:(ARTCipherParams *)params {
    if (!params) {
        params = [self defaultParams];
    }

    return [ARTCbcCipher cbcCipherWithParams:params];
}

@end
