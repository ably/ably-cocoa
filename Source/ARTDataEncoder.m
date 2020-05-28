//
//  ARTDataEncoder.m
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTCrypto+Private.h"
#import "ARTLog.h"
#import "ARTDataEncoder.h"
#import "ARTDeltaCodec.h"

@implementation ARTDataEncoderOutput

- (id)initWithData:(id)data encoding:(NSString *)encoding errorInfo:(ARTErrorInfo *)errorInfo {
    self = [super init];
    if (self) {
        _data = data;
        _encoding = encoding;
        _errorInfo = errorInfo;
    }
    return self;
}

@end

@implementation ARTDataEncoder {
    id<ARTChannelCipher> _cipher;
    id<ARTVCDiffDecoder> _vcdiffDecoder;
    NSData *_lastMessageData;
}

- (instancetype)initWithCipherParams:(ARTCipherParams *)params error:(NSError **)error {
    self = [super init];
    if (self) {
        if (params) {
            _cipher = [ARTCrypto cipherWithParams:params];
            if (!_cipher) {
                if (error) {
                    NSString *desc = [NSString stringWithFormat:@"ARTDataEncoder failed to create cipher with name %@", params.algorithm];
                    *error = [NSError errorWithDomain:ARTAblyErrorDomain
                                                 code:0
                                             userInfo:@{NSLocalizedDescriptionKey: desc}];
                }
                return nil;
            }
        }

        _vcdiffDecoder = [[ARTDeltaCodec alloc] init];
    }
    return self;
}

- (void)setLastMessageData:(nullable id)data {
    if ([data isKindOfClass:[NSData class]]) {
        _lastMessageData = data;
    }
    else if ([data isKindOfClass:[NSString class]]) {
        _lastMessageData = [data dataUsingEncoding:NSUTF8StringEncoding];
    }
}

- (ARTDataEncoderOutput *)encode:(id)data {
    NSString *encoding = nil;
    id encoded = nil;
    NSData *toBase64 = nil;

    if (!data) {
        return [[ARTDataEncoderOutput alloc] initWithData:data encoding:nil errorInfo:nil];
    }

    NSData *jsonEncoded = nil;
    if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]]) {
        NSError *error = nil;
        // Just check the error; we don't want to actually JSON-encode this. It's more like "convert to JSON-compatible data".
        // We will store the result, though, because if we're encrypting, then yes, we need to use the JSON-encoded
        // data before encrypting.
        NSJSONWritingOptions options;
        if (@available(iOS 11.0, *)) {
            options = NSJSONWritingSortedKeys;
        }
        else {
            options = 0;
        }
        jsonEncoded = [NSJSONSerialization dataWithJSONObject:data options:options error:&error];
        if (error) {
            return [[ARTDataEncoderOutput alloc] initWithData:data encoding:nil errorInfo:[ARTErrorInfo createFromNSError:error]];
        }
        encoded = data;
        encoding = @"json";
    } else if ([data isKindOfClass:[NSString class]]) {
        encoding = @"";
        encoded = data;
    } else if ([data isKindOfClass:[NSData class]]) {
        encoded = data;
        toBase64 = data;
    }

    if (_cipher) {
        if ([encoded isKindOfClass:[NSArray class]] || [encoded isKindOfClass:[NSDictionary class]]) {
            encoded = jsonEncoded;
            encoding = [NSString artAddEncoding:@"utf-8" toString:encoding];
        } else if ([encoded isKindOfClass:[NSString class]]) {
            encoded = [data dataUsingEncoding:NSUTF8StringEncoding];
            encoding = [NSString artAddEncoding:@"utf-8" toString:encoding];
        }
        ARTStatus *status = [_cipher encrypt:encoded output:&toBase64];
        if (status.state != ARTStateOk) {
            ARTErrorInfo *errorInfo = status.errorInfo ? status.errorInfo : [ARTErrorInfo createWithCode:0 message:@"encrypt failed"];
            return [[ARTDataEncoderOutput alloc] initWithData:encoded encoding:encoding errorInfo:errorInfo];
        }
        encoding = [NSString artAddEncoding:[self cipherEncoding] toString:encoding];
    } else if (jsonEncoded) {
        encoded = [[NSString alloc] initWithData:jsonEncoded encoding:NSUTF8StringEncoding];
    }

    if (toBase64 != nil) {
        encoded = [[toBase64 base64EncodedStringWithOptions:0] dataUsingEncoding:NSUTF8StringEncoding];
        if (!encoded) {
            return [[ARTDataEncoderOutput alloc] initWithData:toBase64 encoding:encoding errorInfo:[ARTErrorInfo createWithCode:0 message:@"base64 failed"]];
        }
        encoded = [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];
        encoding = [NSString artAddEncoding:@"base64" toString:encoding];
    }

    if (encoded == nil) {
        return [[ARTDataEncoderOutput alloc] initWithData:data encoding:nil errorInfo:[ARTErrorInfo createWithCode:0 message:@"must be NSString, NSData, NSArray or NSDictionary."]];
    }

    return [[ARTDataEncoderOutput alloc] initWithData:encoded
                                             encoding:encoding
                                            errorInfo:nil];
}

- (ARTDataEncoderOutput *)decode:(id)data encoding:(NSString *)encoding {
    if (!data || !encoding ) {
        [self setLastMessageData:data];
        return [[ARTDataEncoderOutput alloc] initWithData:data encoding:encoding errorInfo:nil];
    }
    
    ARTErrorInfo *errorInfo = nil;
    NSArray *encodings = [encoding componentsSeparatedByString:@"/"];
    NSString *outputEncoding = [NSString stringWithString:encoding];
    
    for (NSUInteger i = [encodings count]; i > 0; i--) {
        errorInfo = nil;
        NSString *encoding = [encodings objectAtIndex:i-1];

        if ([encoding isEqualToString:@"base64"]) {
            if ([data isKindOfClass:[NSData class]]) { // E. g. when decrypted.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            if ([data isKindOfClass:[NSString class]]) {
                data = [[NSData alloc] initWithBase64EncodedString:(NSString *)data options:0];
            } else {
                errorInfo = [ARTErrorInfo createWithCode:40013 message:[NSString stringWithFormat:@"invalid data type for 'base64' decoding: '%@'", [data class]]];
            }
        } else if ([encoding isEqualToString:@""] || [encoding isEqualToString:@"utf-8"]) {
            if ([data isKindOfClass:[NSData class]]) { // E. g. when decrypted.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            if (![data isKindOfClass:[NSString class]]) {
                errorInfo = [ARTErrorInfo createWithCode:40013 message:[NSString stringWithFormat:@"invalid data type for '%@' decoding: '%@'", encoding, [data class]]];
            }
        } else if ([encoding isEqualToString:@"json"]) {
            if ([data isKindOfClass:[NSData class]]) { // E. g. when decrypted.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            if ([data isKindOfClass:[NSString class]]) {
                NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                if (error != nil) {
                    errorInfo = [ARTErrorInfo createFromNSError:error];
                }
            } else if (![data isKindOfClass:[NSArray class]] && ![data isKindOfClass:[NSDictionary class]]) {
                errorInfo = [ARTErrorInfo createWithCode:40013 message:[NSString stringWithFormat:@"invalid data type for 'json' decoding: '%@'", [data class]]];
            }
        } else if (_cipher && [encoding isEqualToString:[self cipherEncoding]] && [data isKindOfClass:[NSData class]]) {
            ARTStatus *status = [_cipher decrypt:data output:&data];
            if (status.state != ARTStateOk) {
                errorInfo = status.errorInfo ? status.errorInfo : [ARTErrorInfo createWithCode:40013 message:@"decrypt failed"];
            }
        } else if ([encoding isEqualToString:@"vcdiff"]) {
            NSError *decodeError;
            if (_vcdiffDecoder) {
                NSData *delta = data;
                NSData *base = _lastMessageData;
                data = [_vcdiffDecoder decode:delta base:base error:&decodeError];
            }
            else {
                errorInfo = [ARTErrorInfo createWithCode:40018 message:@"VCDiffDecoder is missing"];
            }

            if (decodeError) {
                errorInfo = [ARTErrorInfo createWithCode:40018 message:decodeError.localizedDescription];
            }
            else if (!data) {
                errorInfo = [ARTErrorInfo createWithCode:40018 message:@"Data is nil"];
            }
        } else {
            errorInfo = [ARTErrorInfo createWithCode:40013 message:[NSString stringWithFormat:@"unknown encoding: '%@'", encoding]];
        }

        [self setLastMessageData:data];

        if (errorInfo == nil) {
            outputEncoding = [outputEncoding artRemoveLastEncoding];
        } else {
            break;
        }
    }
    
    return [[ARTDataEncoderOutput alloc] initWithData:data
                                             encoding:outputEncoding
                                            errorInfo:errorInfo];
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
