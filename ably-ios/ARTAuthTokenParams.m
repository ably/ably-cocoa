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

#import "ARTEncoder.h"
#import "ARTPayload.h"
#import "ARTAuthTokenRequest.h"

@implementation ARTAuthTokenParams

- (instancetype)init {
    if (self = [super init]) {
        _ttl = 60 * 60;
        _timestamp = [NSDate date];
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

static NSString *generateNonce() {
    // Generate two random numbers up to 8 digits long and concatenate them to produce a 16 digit random number
    NSUInteger r1 = arc4random_uniform(100000000);
    NSUInteger r2 = arc4random_uniform(100000000);
    return [NSString stringWithFormat:@"%08lu%08lu", (long)r1, (long)r2];
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
    NSArray *keyComponents = decomposeKey(key);
    NSString *keyName = keyComponents[0];
    NSString *keySecret = keyComponents[1];
    NSString *nonce = generateNonce();
    NSString *clientId = self.clientId ? self.clientId : @"";

    NSString *signText = [NSString stringWithFormat:@"%@\n%lld\n%@\n%@\n%lld\n%@\n", keyName, timeIntervalToMiliseconds(self.ttl), self.capability, clientId, dateToMiliseconds(self.timestamp), nonce];
    NSString *mac = hmacForDataAndKey([signText dataUsingEncoding:NSUTF8StringEncoding], [keySecret dataUsingEncoding:NSUTF8StringEncoding]);
    
    return [[ARTAuthTokenRequest alloc] initWithTokenParams:self keyName:keyName nonce:nonce mac:mac];
}

@end
