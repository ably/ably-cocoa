//
//  ARTDataEncoder.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTCrypto.h"
#import "ARTLog.h"
#import "ARTDataEncoder.h"

@interface ARTDataEncoder ()

ART_ASSUME_NONNULL_BEGIN

@property (readonly, nonatomic) ARTLog *logger;

ART_ASSUME_NONNULL_END

@end

@implementation ARTDataEncoderOutput

- (id)initWithData:(id)data encoding:(NSString *)encoding status:(ARTStatus *)status {
    self = [super init];
    if (self) {
        _data = data;
        _encoding = encoding;
        _status = status;
    }
    return self;
}

@end

@implementation ARTDataEncoder {
    id<ARTChannelCipher> _cipher;
}

- (instancetype)initWithCipherParams:(ARTCipherParams *)params logger:(ARTLog *)logger {
    self = [super init];
    if (self) {
        _logger = logger;
        if (params) {
            _cipher = [ARTCrypto cipherWithParams:params];
            if (!_cipher) {
                [self.logger error:@"ARTDataEncoder failed to create cipher with name %@", params.algorithm];
            }
        }
    }
    return self;
}

- (ARTDataEncoderOutput *)encode:(id)data {
    NSString *encoding = nil;
    NSData *encoded = nil;
    NSData *toBase64 = nil;

    if (!data) {
        return [[ARTDataEncoderOutput alloc] initWithData:data encoding:nil status:[ARTStatus state:ARTStateOk]];
    }

    if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]]) {
        NSError *error = nil;
        encoded = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        if (error) {
            ARTStatus *status = [ARTStatus state:ARTStateError info:[ARTErrorInfo createWithNSError:error]];
            return [[ARTDataEncoderOutput alloc] initWithData:data encoding:nil status:status];
        }
        encoding = @"json/utf-8";
    } else if ([data isKindOfClass:[NSString class]]) {
        encoding = @"utf-8";
        encoded = [data dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([data isKindOfClass:[NSData class]]) {
        encoded = data;
        toBase64 = data;
    }

    if (_cipher) {
        ARTStatus *status = [_cipher encrypt:encoded output:&toBase64];
        if (status.state != ARTStateOk) {
            return [[ARTDataEncoderOutput alloc] initWithData:encoded encoding:encoding status:status];
        }
        encoding = [NSString artAddEncoding:[self cipherEncoding] toString:encoding];
    }

    if (toBase64 != nil) {
        encoded = [[toBase64 base64EncodedStringWithOptions:0] dataUsingEncoding:NSUTF8StringEncoding];
        if (!encoded) {
            return [[ARTDataEncoderOutput alloc] initWithData:toBase64 encoding:encoding status:[ARTStatus state:ARTStateError]];
        }
        encoding = [NSString artAddEncoding:@"base64" toString:encoding];
    }

    if (encoded == nil) {
        NSError *error = [NSError errorWithDomain:ARTAblyErrorDomain code:0 userInfo:@{@"reason": @"must be NSString, NSData, NSArray or NSDictionary."}];
        ARTStatus *status = [ARTStatus state:ARTStateError info:[ARTErrorInfo createWithNSError:error]];
        return [[ARTDataEncoderOutput alloc] initWithData:data encoding:nil status:status];
    }

    return [[ARTDataEncoderOutput alloc] initWithData:[[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding]
                                             encoding:encoding
                                               status:[ARTStatus state:ARTStateOk]];
}

- (ARTDataEncoderOutput *)decode:(id)data encoding:(NSString *)encoding {
    if (!data || !encoding ) {
        return [[ARTDataEncoderOutput alloc] initWithData:data encoding:encoding status:[ARTStatus state:ARTStateOk]];
    }
    
    BOOL ok = false;
    NSArray *encodings = [encoding componentsSeparatedByString:@"/"];
    NSString *outputEncoding = [NSString stringWithString:encoding];
    
    for (NSUInteger i = [encodings count]; i > 0; i--) {
        ok = false;
        NSString *encoding = [encodings objectAtIndex:i-1];
        
        if ([encoding isEqualToString:@"base64"]) {
            if ([data isKindOfClass:[NSData class]]) { // E. g. when decrypted.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            if ([data isKindOfClass:[NSString class]]) {
                data = [[NSData alloc] initWithBase64EncodedString:(NSString *)data options:0];
                ok = data != nil;
            }
        } else if ([encoding isEqualToString:@""] || [encoding isEqualToString:@"utf-8"]) {
            if ([data isKindOfClass:[NSData class]]) { // E. g. when decrypted.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            ok = [data isKindOfClass:[NSString class]];
        } else if ([encoding isEqualToString:@"json"]) {
            if ([data isKindOfClass:[NSData class]]) { // E. g. when decrypted.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            if ([data isKindOfClass:[NSString class]]) {
                NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
                data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                ok = data != nil;
            }
        } else if (_cipher && [encoding isEqualToString:[self cipherEncoding]] && [data isKindOfClass:[NSData class]]) {
            ARTStatus *status = [_cipher decrypt:data output:&data];
            ok = status.state == ARTStateOk;
        }
        
        if (ok) {
            outputEncoding = [outputEncoding artRemoveLastEncoding];
        } else {
            [self.logger error:@"ARTDataDecoded failed to decode data as '%@': (%@)%@", encoding, [data class], data];
            break;
        }
    }
    
    return [[ARTDataEncoderOutput alloc] initWithData:data
                                             encoding:outputEncoding
                                               status:[ARTStatus state:(ok ? ARTStateOk : ARTStateError)]];
}

- (NSString *)cipherEncoding {
    size_t keyLen = [_cipher keyLength];
    if (keyLen == 128) {
        return @"cipher+aes-128-cbc";
    } else if (keyLen == 256) {
        return @"cipher+aes-256-cbc";
    }
    return nil;
}

@end

@implementation NSString (ARTPayload)

+ (NSString *)artAddEncoding:(NSString *)encoding toString:(NSString *)s {
    return [(s ? s : @"") stringByAppendingPathComponent:encoding];
}

- (NSString *)artLastEncoding {
    return [self lastPathComponent];
}

- (NSString *)artRemoveLastEncoding {
    NSString *encoding = [self stringByDeletingLastPathComponent];
    if ([encoding length] == 0) {
        return nil;
    }
    return encoding;
}

@end
