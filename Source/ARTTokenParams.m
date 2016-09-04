//
//  ARTTokenParams.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTTokenParams+Private.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#import "ARTDefault.h"
#import "ARTEncoder.h"
#import "ARTTokenRequest.h"

@implementation ARTTokenParams {
    NSDate *_timestamp;
}

- (instancetype)init {
    return [self initWithClientId:nil nonce:nil];
}

- (instancetype)initWithClientId:(NSString *)clientId {
    return [self initWithClientId:clientId nonce:nil];
}

- (instancetype)initWithClientId:(NSString *)clientId nonce:(NSString *)nonce {
    if (self = [super init]) {
        _timestamp = nil;
        _ttl = [ARTDefault ttl];
        _capability = @"{\"*\":[\"*\"]}"; // allow all
        _clientId = clientId;
        _nonce = nonce;
    }
    return self;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [self initWithClientId:options.clientId];
    if (options.defaultTokenParams) {
        if (options.defaultTokenParams.ttl) _ttl = options.defaultTokenParams.ttl;
        if (options.defaultTokenParams.capability) _capability = options.defaultTokenParams.capability;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTTokenParams *tokenParams = [[[self class] allocWithZone:zone] init];
    
    tokenParams.ttl = self.ttl;
    tokenParams.capability = self.capability;
    tokenParams.clientId = self.clientId;
    tokenParams.timestamp = self.timestamp;
    tokenParams.nonce = self.nonce;
    
    return tokenParams;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTTokenParams: ttl=%f capability=%@ timestamp=%@",
            self.ttl, self.capability, self.timestamp];
}

- (void)setTimestamp:(NSDate *)timestamp {
    _timestamp = timestamp;
}

- (NSDate *)getTimestamp {
    if (_timestamp == nil) {
        _timestamp = [NSDate date];
    }
    return _timestamp;
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
    NSString *str = [mac base64EncodedStringWithOptions:0];
    return str;
}

- (ARTTokenRequest *)sign:(NSString *)key {
    return [self sign:key withNonce:self.nonce ? self.nonce : generateNonce()];
}

- (ARTTokenRequest *)sign:(NSString *)key withNonce:(NSString *)nonce {
    NSArray *keyComponents = decomposeKey(key);
    NSString *keyName = keyComponents[0];
    NSString *keySecret = keyComponents[1];
    NSString *clientId = self.clientId ? self.clientId : @"";
    
    NSString *signText = [NSString stringWithFormat:@"%@\n%lld\n%@\n%@\n%lld\n%@\n", keyName, timeIntervalToMiliseconds(self.ttl), self.capability, clientId, dateToMiliseconds(self.timestamp), nonce];
    NSString *mac = hmacForDataAndKey([signText dataUsingEncoding:NSUTF8StringEncoding], [keySecret dataUsingEncoding:NSUTF8StringEncoding]);
    
    return [[ARTTokenRequest alloc] initWithTokenParams:self keyName:keyName nonce:nonce mac:mac];
}

- (ARTTokenParams *)replaceWith:(ARTTokenParams *)params {
    ARTTokenParams *replaced = [self copy];
    
    @synchronized (self) {
        if (params != nil) {
            replaced.ttl = params.ttl;
            replaced.capability = params.capability;
            replaced.clientId = params.clientId;
            replaced.timestamp = params.timestamp;
            replaced.nonce = params.nonce;
        }
    }
    
    return replaced;
}

@end
