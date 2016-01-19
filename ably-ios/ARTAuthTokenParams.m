//
//  ARTAuthTokenParams.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuthTokenParams.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#import "ARTDefault.h"
#import "ARTEncoder.h"
#import "ARTPayload.h"
#import "ARTAuthTokenRequest.h"

@implementation ARTAuthTokenParams

- (instancetype)init {
    if (self = [super init]) {
        _timestamp = [NSDate date];
        _ttl = [ARTDefault ttl];
        _capability = @"{\"*\":[\"*\"]}"; // allow all
        _clientId = nil;
    }
    return self;
}

- (instancetype)initWithClientId:(NSString *)clientId {
    if (self = [self init]) {
        _clientId = clientId;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTAuthTokenParams: ttl=%f capability=%@ timestamp=%@",
            self.ttl, self.capability, self.timestamp];
}

- (void)setTimestamp:(NSDate *)timestamp {
    if (timestamp == nil) {
        timestamp = [NSDate date];
    }
    
    _timestamp = timestamp;
}

- (NSMutableArray *)toArray {
    NSMutableArray *params = [[NSMutableArray alloc] init];
    
    if (self.clientId)
        [params addObject:[NSURLQueryItem queryItemWithName:@"clientId" value:self.clientId]];
    if (self.ttl > 0)
        [params addObject:[NSURLQueryItem queryItemWithName:@"ttl" value:[NSString stringWithFormat:@"%f", self.ttl]]];
    if (self.capability)
        [params addObject:[NSURLQueryItem queryItemWithName:@"capability" value:self.capability]];
    if (self.timestamp > 0)
        [params addObject:[NSURLQueryItem queryItemWithName:@"timestamp" value:[NSString stringWithFormat:@"%f", self.timestamp.timeIntervalSince1970]]];
    
    return params;
}

- (NSMutableDictionary *)toDictionary {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (self.clientId)
        params[@"clientId"] = self.clientId;
    if (self.ttl > 0)
        params[@"ttl"] = [NSString stringWithFormat:@"%f", self.ttl];
    if (self.capability)
        params[@"capability"] = self.capability;
    if (self.timestamp > 0)
        params[@"timestamp"] = [NSString stringWithFormat:@"%f", self.timestamp.timeIntervalSince1970];
    
    return params;
}

- (NSArray *)toArrayWithUnion:(NSArray *)items {
    NSMutableArray *tokenParams = [self toArray];
    BOOL add = YES;
    
    for (NSURLQueryItem *item in items) {
        for (NSURLQueryItem *param in tokenParams) {
            // Check if exist
            if ([param.name isEqualToString:item.name]) {
                add = NO;
                break;
            }
        }
        if (add) {
            [tokenParams addObject:item];
        }
        add = YES;
    }
    
    return tokenParams;
}

- (NSDictionary *)toDictionaryWithUnion:(NSArray *)items {
    NSMutableDictionary *tokenParams = [self toDictionary];
    BOOL add = YES;
    
    for (NSURLQueryItem *item in items) {
        for (NSString *key in tokenParams.allKeys) {
            // Check if exist
            if ([key isEqualToString:item.name]) {
                add = NO;
                break;
            }
        }
        if (add) {
            tokenParams[item.name] = item.value;
        }
        add = YES;
    }
    
    return tokenParams;
}

static NSString *hmacForDataAndKey(NSData *data, NSData *key) {
    const void *cKey = [key bytes];
    const void *cData = [data bytes];
    size_t keyLen = [key length];
    size_t dataLen = [data length];
    
    unsigned char hmac[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, keyLen, cData, dataLen, hmac);
    NSData *mac = [[NSData alloc] initWithBytes:hmac length:sizeof(hmac)];
    NSString *str = [ARTBase64PayloadEncoder toBase64:mac];
    return str;
}

- (ARTAuthTokenRequest *)sign:(NSString *)key {
    return [self sign:key withNonce:generateNonce()];
}

- (ARTAuthTokenRequest *)sign:(NSString *)key withNonce:(NSString *)randomNonce {
    NSArray *keyComponents = decomposeKey(key);
    NSString *keyName = keyComponents[0];
    NSString *keySecret = keyComponents[1];
    NSString *nonce = randomNonce;
    NSString *clientId = self.clientId ? self.clientId : @"";

    NSString *signText = [NSString stringWithFormat:@"%@\n%lld\n%@\n%@\n%lld\n%@\n", keyName, timeIntervalToMiliseconds(self.ttl), self.capability, clientId, dateToMiliseconds(self.timestamp), nonce];
    NSString *mac = hmacForDataAndKey([signText dataUsingEncoding:NSUTF8StringEncoding], [keySecret dataUsingEncoding:NSUTF8StringEncoding]);

    return [[ARTAuthTokenRequest alloc] initWithTokenParams:self keyName:keyName nonce:nonce mac:mac];
}

@end
