//
//  ARTPayload.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTPayload+Private.h"

#import "ARTCrypto.h"
#import "ARTLog.h"

@interface ARTBase64PayloadEncoder ()

+ (BOOL)canEncode:(ARTPayload *)payload;
+ (BOOL)canDecode:(ARTPayload *)payload;

@end

@interface ARTCipherPayloadEncoder ()

@property (nonatomic, weak) ARTLog *logger;
@property (readonly, strong, nonatomic) id<ARTChannelCipher> cipher;

@end

@interface ARTPayloadEncoderChain ()

@property (nonatomic, weak) ARTLog *logger;
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

    NSMutableArray *encoders = [NSMutableArray arrayWithObjects:[ARTJsonPayloadEncoder instance], [ARTUtf8PayloadEncoder instance], nil];

    ARTCipherPayloadEncoder *cipherEncoder = [[ARTCipherPayloadEncoder alloc] initWithCipherParams:cipherParams];
    if (cipherEncoder) {
        [encoders addObject:cipherEncoder];
    }

    return [[ARTPayloadEncoderChain alloc] initWithEncoders:encoders];
}

+ (id<ARTPayloadEncoder>)createEncoder:(NSString *) name key:(NSData *) keySpec iv:(NSData *) iv {
    if([name isEqualToString:@"json"]) {
        return [ARTJsonPayloadEncoder instance];
    }
    else if([name isEqualToString:@"base64"]) {
        return [ARTBase64PayloadEncoder instance];
    }
    else if([name isEqualToString:@"utf-8"]) {
        return [ARTUtf8PayloadEncoder instance];
    }
    //256 on iOS is handled by passing the keyLength into kCCAlgorithmAES128
    else if([name isEqualToString:@"cipher+aes-256-cbc"] || [name isEqualToString:@"cipher+aes-128-cbc"]){
        ARTIvParameterSpec * ivSpec = [[ARTIvParameterSpec alloc] initWithIv:iv];
        ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" keySpec:keySpec ivSpec:ivSpec];
        return [[ARTCipherPayloadEncoder alloc] initWithCipherParams:params];
    }
    return nil;
}

+ (NSArray *)parseEncodingChain:(NSString *) encodingChain key:(NSData *) key iv:(NSData *) iv {
    NSArray * strArray = [encodingChain componentsSeparatedByString:@"/"];
    NSMutableArray * encoders= [[NSMutableArray alloc] init];
    size_t l = [strArray count];
    for(int i=0;i < l; i++) {
        NSString * encoderName = [strArray objectAtIndex:i];
        id<ARTPayloadEncoder> encoder = [ARTPayload createEncoder:encoderName key:key iv:iv];
        if(encoder != nil) {
            [encoders addObject:encoder];
        }
    }
    return encoders;
}

+ (size_t) payloadArraySizeLimit {
    return [ARTPayload getPayloadArraySizeLimit:0 modify:false];
}

+ (size_t)getPayloadArraySizeLimit:(size_t) newLimit modify:(bool) modify  {
    static size_t limit = SIZE_T_MAX;
    if(modify) {
        limit = newLimit;
    }
    return limit;
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

+ (NSString *)toBase64:(NSData *) input {
    ARTPayload * p = [[ARTPayload alloc] initWithPayload:input encoding:@"base64"];
    ARTPayload * output = nil;
    ARTBase64PayloadEncoder * e = [ARTBase64PayloadEncoder instance];
    [e encode:p output:&output];
    return output.payload;
}

+ (NSString *)fromBase64:(NSString *) base64 {
    ARTPayload * p = [[ARTPayload alloc] initWithPayload:base64 encoding:@"base64"];
    ARTPayload * output = nil;
    ARTBase64PayloadEncoder * e = [ARTBase64PayloadEncoder instance];
    [e decode:p output:&output];
    return [[NSString alloc] initWithData:output.payload encoding:NSUTF8StringEncoding];
}

+ (NSString *)getName {
    return @"base64";
}
- (NSString *)name {
    return [ARTBase64PayloadEncoder getName];
}

+ (BOOL)canEncode:(ARTPayload *)payload {
    return [payload.payload isKindOfClass:[NSData class]];
}

+ (BOOL)canDecode:(ARTPayload *)payload {
    return [payload.encoding isEqualToString:[ARTBase64PayloadEncoder getName]];
}

- (ARTStatus *)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    if ([ARTBase64PayloadEncoder canEncode:payload]) {
        NSString *encoded = [((NSData *)payload.payload) base64EncodedStringWithOptions:0];
        if (encoded) {
            *output = [ARTPayload payloadWithPayload:encoded encoding:[payload.encoding artAddEncoding:[ARTBase64PayloadEncoder getName]]];
            return [ARTStatus state:ARTStateOk];
        } else {
            // Set the output to be the original payload
            *output = payload;
            return [ARTStatus state:ARTStateError];
        }
    }
    *output = payload;
    return [ARTStatus state:ARTStateOk];
}

- (ARTStatus *)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    if ([[payload.encoding artLastEncoding] isEqualToString:[ARTBase64PayloadEncoder getName]]) {//[ARTBase64PayloadEncoder canDecode:payload]) {
        NSData *decoded = [[NSData alloc] initWithBase64EncodedString:payload.payload options:0];
        if (decoded) {
            *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
            return [ARTStatus state:ARTStateOk];
        }
        // Set the output to be the original payload
        *output = payload;
        return [ARTStatus state:ARTStateError];
    }
    *output = payload;
    return [ARTStatus state:ARTStateOk];
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

+ (NSString *)getName {
    return @"utf-8";
}

- (NSString *)name {
    return [ARTUtf8PayloadEncoder getName];
}

- (ARTStatus *)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([[payload.encoding artLastEncoding] isEqualToString:[ARTUtf8PayloadEncoder getName]]) {
        if ([payload.payload isKindOfClass:[NSData class]]) {
            NSString *decoded = [[NSString alloc] initWithData:payload.payload encoding:NSUTF8StringEncoding];
            if (decoded) {
                *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
                return [ARTStatus state:ARTStateOk];
            }
        }
        return [ARTStatus state:ARTStateError];
    }
    return [ARTStatus state:ARTStateOk];
}

- (ARTStatus *)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([payload isKindOfClass:[NSString class]]) {
        NSData *encoded = [((NSString *)payload.payload) dataUsingEncoding:NSUTF8StringEncoding];
        if (encoded) {
            *output = [ARTPayload payloadWithPayload:encoded encoding:[payload.encoding artAddEncoding:[ARTUtf8PayloadEncoder getName]]];
            return ARTStateOk;
        }
        return [ARTStatus state:ARTStateError];
    }
    return [ARTStatus state:ARTStateOk];
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

+ (NSString *)getName {
    return @"json";
}
- (NSString *)name {
    return [ARTJsonPayloadEncoder getName];
}

- (ARTStatus *)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    
    //handle dictionaries and arrays the same way
    if ([payload.payload isKindOfClass:[NSDictionary class]] || [payload.payload isKindOfClass:[NSArray class]]) {
        NSError * err = nil;
        NSData *encoded = [NSJSONSerialization dataWithJSONObject:payload.payload options:0 error:&err];

        if (encoded) {
            *output = [ARTPayload payloadWithPayload:encoded encoding:[payload.encoding artAddEncoding:[ARTJsonPayloadEncoder getName]]];
            return [ARTStatus state:ARTStateOk];
        } else {
            return [ARTStatus state:ARTStateError];
        }
    }
    // otherwise do nothing besides confirm payload is nsdata or nsstring
    else if(payload && !([payload.payload isKindOfClass:[NSData class]] || [payload.payload isKindOfClass:[NSString class]])) {
        [NSException raise:@"ARTPayload must be either NSDictionary, NSArray, NSData or NSString" format:@"%@", [payload.payload class]];
    }
    return [ARTStatus state:ARTStateOk];
}

- (ARTStatus *)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([[payload.encoding artLastEncoding] isEqualToString:[ARTJsonPayloadEncoder getName]]) {
        id decoded = nil;

        if ([payload.payload isKindOfClass:[NSString class]]) {
            NSData *d = [payload.payload dataUsingEncoding:NSUTF8StringEncoding];
            decoded = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];

            if (decoded) {
                *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
                return [ARTStatus state:ARTStateOk];
            }
        }
        else if ([payload.payload isKindOfClass:[NSData class]]) {
            decoded = [NSJSONSerialization JSONObjectWithData:(NSData *)payload.payload options:0 error:nil];

            if (decoded) {
                *output = [ARTPayload payloadWithPayload:decoded encoding:[payload.encoding artRemoveLastEncoding]];
                return [ARTStatus state:ARTStateOk];
            }
        }
        return [ARTStatus state:ARTStateError];
    }
    return [ARTStatus state:ARTStateOk];
}

@end

@implementation ARTCipherPayloadEncoder

- (instancetype)initWithCipherParams:(ARTCipherParams *)cipherParams {
    self = [super init];
    if (self) {
        _cipher = [ARTCrypto cipherWithParams:cipherParams];
        if (!_cipher) {
            [self.logger error:@"ARTCipherPayloadEncoder failed to create cipher with name %@", cipherParams.algorithm];
            self = nil;
            return nil;
        }
    }
    return self;
}

+ (NSString *)getName128 {
    return @"cipher+aes-128-cbc";
}

+ (NSString *)getName256 {
    return @"cipher+aes-256-cbc";
}

- (NSString *)name {
    size_t keyLen =[self.cipher keyLength];
    if (keyLen == 128) {
        return [ARTCipherPayloadEncoder getName128];
    }
    else if(keyLen == 256) {
        return [ARTCipherPayloadEncoder getName256];
    }
    else {
        [self.logger error:@"ARTPayload: keyLength is invalid %zu", keyLen];
    }
    return @"";
}

- (ARTStatus *)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;

    NSString * cipherName =[payload.encoding artLastEncoding];
    if ([payload.payload isKindOfClass:[NSData class]] && [cipherName isEqualToString:[self name]]) {
        NSData *decrypted = nil;
        ARTStatus * status = [self.cipher decrypt:payload.payload output:&decrypted];
        if (status.state == ARTStateOk) {
            *output = [ARTPayload payloadWithPayload:decrypted encoding:[payload.encoding artRemoveLastEncoding]];
            [self.logger debug:@"cipher payload decoded successfully"];
        }
        return status;
    }

    return [ARTStatus state:ARTStateOk];
}

- (ARTStatus *)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    *output = payload;
    if ([payload.payload isKindOfClass:[NSData class]]) {
        NSData *encrypted = nil;
        ARTStatus *status = [self.cipher encrypt:payload.payload output:&encrypted];
        if (status.state == ARTStateOk) {
            NSString *cipherName = [self name];
            *output = [ARTPayload payloadWithPayload:encrypted encoding:[payload.encoding artAddEncoding:cipherName]];
        }
        return status;
    }
    return [ARTStatus state:ARTStateOk];
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

- (NSString *)name {
    return @"chain"; //not used.
}

- (ARTStatus *)encode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    ARTStatus *status = ARTStateOk;
    *output = payload;

    for (id<ARTPayloadEncoder> enc in self.encoders) {
        status = [enc encode:*output output:output];
        if (status.state != ARTStateOk) {
            break;
        }
    }

    return status;
}

- (ARTStatus *)decode:(ARTPayload *)payload output:(ARTPayload *__autoreleasing *)output {
    ARTStatus *status = [ARTStatus state:ARTStateOk];
    *output = payload;

    int count=0;
    for (id<ARTPayloadEncoder> enc in self.encoders.reverseObjectEnumerator) {
        status = [enc decode:*output output:output];
        if (status.state != ARTStateOk) {
            ARTPayload * p  = *output;
            [self.logger error:@"ARTPayload: error in ARTPayloadEncoderChain decoding with encoder %d. Remaining decoding jobs are %@", count, p.encoding];
            break;
        }
        count++;
    }

    return status;
}

@end
