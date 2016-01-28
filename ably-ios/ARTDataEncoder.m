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

@implementation ARTDataEncoder {
    id<ARTChannelCipher> _cipher;
    ARTLog *_logger;
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

- (ARTStatus *__art_nullable)encode:(id)data outputData:(id __art_nullable *__art_nonnull)outputData outputEncoding:(NSString **)outputEncoding {
    NSData *encoded = nil;
    NSString *encoding = nil;
    BOOL ok = false;
    
    if (!data) {
        *outputData = nil;
        *outputEncoding = nil;
        return [ARTStatus state:ARTStateOk];
    } else if ([data isKindOfClass:[NSData class]]) {
        encoding = @"base64";
        encoded = [[((NSData *)data) base64EncodedStringWithOptions:0] dataUsingEncoding:NSUTF8StringEncoding];
        ok = encoded != nil;
    } else if ([data isKindOfClass:[NSString class]]) {
        encoding = @"";
        encoded = [data dataUsingEncoding:NSUTF8StringEncoding];
        ok = true;
    } else if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]]) {
        encoding = @"json";
        NSError *error = nil;
        encoded = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        ok = error == nil && encoded != nil;
    }
    
    if (!ok) {
        return [ARTStatus state:ARTStateError];
    }
    
    if (_cipher) {
        ARTStatus *status = [_cipher encrypt:encoded output:&encoded];
        if (status.state != ARTStateOk) {
            return status;
        }
        encoding = [encoding artAddEncoding:[self cipherEncoding]];
        
        // Re-encode the encrypted bytes in base64.
        encoded = [[encoded base64EncodedStringWithOptions:0] dataUsingEncoding:NSUTF8StringEncoding];
        if (encoded == nil) {
            return [ARTStatus state:ARTStateError];
        }
        encoding = [encoding artAddEncoding:@"base64"];
    }
    
    *outputData =  [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];
    *outputEncoding = encoding;
    return [ARTStatus state:ARTStateOk];
}

- (ARTStatus *__art_nullable)decode:(id)data encoding:(NSString *)encoding outputData:(id __art_nullable *__art_nonnull)outputData outputEncoding:(NSString **)outputEncoding {
    if (!data || !encoding ) {
        *outputData = data;
        *outputEncoding = encoding;
        return [ARTStatus state:ARTStateOk];
    }
    
    BOOL ok = false;
    NSArray *encodings = [encoding componentsSeparatedByString:@"/"];
    *outputEncoding = [NSString stringWithString:encoding];
    
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
        } else if ([encoding isEqualToString:@""]) {
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
            if (i == 1) {
                // Because strings have no encoding, an encoded payload whose left-most encoding
                // is a cipher will be a string.
                data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            ok = status.state == ARTStateOk;
        }
        
        if (ok) {
            *outputEncoding = [*outputEncoding artRemoveLastEncoding];
        } else {
            [self.logger error:@"ARTDataDecoded failed to decode data as '%@': (%@)%@", encoding, [data class], data];
        }
    }
    
    *outputData = data;
    if (ok) {
        return [ARTStatus state:ARTStateOk];
    } else {
        return [ARTStatus state:ARTStateError];
    }
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
