//
//  ARTPayload.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTPayload.h"
#import "ARTCrypto.h"

@interface ARTBase64PayloadEncoder ()

+ (NSString *)name;
+ (BOOL)canEncode:(ARTPayload *)payload;
+ (BOOL)canDecode:(ARTPayload *)payload;

@end

@interface ARTCipherPayloadEncoder ()

@property (readonly, strong, nonatomic) id<ARTChannelCipher> cipher;

@end

@interface ARTPayloadEncoderChain ()

@property (readonly, nonatomic, strong) NSArray *encoders;

@end

@implementation ARTPayload

- (instancetype)init {
    return [self initWithPayload:nil encoding:@""];
}

- (instancetype)initWithPayload:(id)payload encoding:(NSString *)encoding {
    self = [super init];
    if (self) {
        _payload = payload;
        _encoding = encoding;
    }
    return self;
}

+ (instancetype)payload {
    return [[ARTPayload alloc] init];
}

+ (instancetype)payloadWithPayload:(id)payload encoding:(NSString *)encoding {
    return [[ARTPayload alloc] initWithPayload:payload encoding:encoding];
}

+ (id<ARTPayloadEncoder>)defaultPayloadEncoder:(ARTCipherParams *)cipherParams {
    if (!cipherParams) {
        return [ARTJsonPayloadEncoder instance];
    }

    return [[ARTPayloadEncoderChain alloc] initWithEncoders:@[
        [ARTJsonPayloadEncoder instance],
        [ARTUtf8PayloadEncoder instance],
        [[ARTCipherPayloadEncoder alloc] initWithCipherParams:cipherParams]]];
}

@end

@implementation NSString (ARTPayload)

- (NSString *)artAddEncoding:(NSString *)encoding {
    return [self stringByAppendingPathComponent:encoding];
}

- (NSString *)artLastEncoding {
    return [self lastPathComponent];
}

- (NSString *)artRemoveLastEncoding {
    return [self stringByDeletingLastPathComponent];
}

@end

@implementation ARTBase64PayloadEncoder

+ (instancetype)instance {
    static ARTBase64PayloadEncoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ARTBase64PayloadEncoder alloc] init];
    });
    return instance;
}

+ (NSString *)name {
    return @"base64";
}

+ (BOOL)canEncode:(ARTPayload *)payload {
    return [payload.payload isKindOfClass:[NSData class]];
}

+ (BOOL)canDecode:(ARTPayload *)payload {
    return [payload.encoding isEqualToString:[ARTBase64PayloadEncoder name]];
}

- (ARTStatus)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    if ([ARTBase64PayloadEncoder canEncode:payload]) {
        NSString *encoded = [((NSData *)payload.payload) base64EncodedStringWithOptions:0];
        if (encoded) {
            *output = [ARTPayload payloadWithPayload:encoded encoding:[payload.encoding artAddEncoding:[ARTBase64PayloadEncoder name]]];
            return ARTStatusOk;
        } else {
            // Set the output to be the original payload
            *output = payload;
            return ARTStatusError;
        }
    }
    *output = payload;
    return ARTStatusOk;
}

- (ARTStatus)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    if ([ARTBase64PayloadEncoder canDecode:payload]) {
        NSData *decoded = [[NSData alloc] initWithBase64EncodedString:payload.payload options:0];
        if (decoded) {
            *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
            return ARTStatusOk;
        }
        // Set the output to be the original payload
        *output = payload;
        return ARTStatusError;
    }
    *output = payload;
    return ARTStatusOk;
}

@end

@implementation ARTUtf8PayloadEncoder

+ (instancetype)instance {
    static ARTUtf8PayloadEncoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ARTUtf8PayloadEncoder alloc] init];
    });
    return instance;
}

- (ARTStatus)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([[payload.encoding artLastEncoding] isEqualToString:@"utf-8"]) {
        if ([payload.payload isKindOfClass:[NSData class]]) {
            NSString *decoded = [[NSString alloc] initWithData:payload.payload encoding:NSUTF8StringEncoding];
            if (decoded) {
                *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
                return ARTStatusOk;
            }
        }
        return ARTStatusError;
    }
    return ARTStatusOk;
}

- (ARTStatus)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([payload isKindOfClass:[NSString class]]) {
        NSData *encoded = [((NSString *)payload.payload) dataUsingEncoding:NSUTF8StringEncoding];
        if (encoded) {
            *output = [ARTPayload payloadWithPayload:encoded encoding:[payload.encoding artAddEncoding:@"utf-8"]];
            return ARTStatusOk;
        }
        return ARTStatusError;
    }
    return ARTStatusOk;
}

@end

@implementation ARTJsonPayloadEncoder

+ (instancetype)instance {
    static ARTJsonPayloadEncoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ARTJsonPayloadEncoder alloc] init];
    });
    return instance;
}

- (ARTStatus)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([payload.payload isKindOfClass:[NSDictionary class]] || [payload.payload isKindOfClass:[NSArray class]]) {
        NSData *encoded = [NSJSONSerialization dataWithJSONObject:payload.payload options:0 error:nil];
        if (encoded) {
            *output = [ARTPayload payloadWithPayload:encoded encoding:[payload.encoding artAddEncoding:@"json"]];
            return ARTStatusOk;
        } else {
            return ARTStatusError;
        }
    }
    return ARTStatusOk;
}

- (ARTStatus)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([[payload.encoding artLastEncoding] isEqualToString:@"json"]) {
        id decoded = nil;
        if ([payload.payload isKindOfClass:[NSString class]]) {
            decoded = [NSJSONSerialization JSONObjectWithData:payload.payload options:0 error:nil];
            if (decoded) {
                *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
                return ARTStatusOk;
            }
        }
        return ARTStatusError;
    }
    return ARTStatusOk;
}

@end

@implementation ARTCipherPayloadEncoder

- (instancetype)initWithCipherParams:(ARTCipherParams *)cipherParams {
    self = [super init];
    if (self) {
        _cipher = [ARTCrypto cipherWithParams:cipherParams];
        if (!_cipher) {
            self = nil;
            return nil;
        }
    }
    return self;
}

- (ARTStatus)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([payload.payload isKindOfClass:[NSData class]] && [[payload.encoding artLastEncoding] hasPrefix:@"cipher+"]) {
        // TODO ensure the suffix of ciper+ is the same as cipher.cipherName?
        NSData *decrypted = nil;
        ARTStatus status = [self.cipher decrypt:payload.payload output:&decrypted];
        if (status == ARTStatusOk) {
            *output = [ARTPayload payloadWithPayload:decrypted encoding:[payload.encoding artRemoveLastEncoding]];
        }
        return status;
    }
    return ARTStatusOk;
}

- (ARTStatus)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([payload.payload isKindOfClass:[NSData class]]) {
        NSData *encrypted = nil;
        ARTStatus status = [self.cipher encrypt:payload.payload output:&encrypted];
        if (status == ARTStatusOk) {
            NSString *cipherName = [NSString stringWithFormat:@"cipher+%@", self.cipher.cipherName];
            *output = [ARTPayload payloadWithPayload:encrypted encoding:[payload.encoding artAddEncoding:cipherName]];
        }
        return status;
    }
    return ARTStatusOk;
}

@end

@implementation ARTPayloadEncoderChain

- (instancetype)init {
    return [self initWithEncoders:@[]];
}

- (instancetype)initWithEncoders:(NSArray *)encoders {
    self = [super init];
    if (self) {
        _encoders = [NSArray arrayWithArray:encoders];
    }
    return self;
}

- (ARTStatus)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    ARTStatus status = ARTStatusOk;
    *output = payload;

    for (id<ARTPayloadEncoder> enc in self.encoders) {
        status = [enc encode:*output output:output];
        if (status != ARTStatusOk) {
            break;
        }
    }

    return status;
}

- (ARTStatus)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    ARTStatus status = ARTStatusOk;
    *output = payload;

    for (id<ARTPayloadEncoder> enc in self.encoders.reverseObjectEnumerator) {
        status = [enc decode:*output output:output];
        if (status != ARTStatusOk) {
            break;
        }
    }

    return status;
}

@end
