//
//  ARTAuth+Private.h
//  ably
//
//  Created by Ricardo Pereira on 03/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuth.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTAuth ()

@property (nonatomic, readonly, strong) ARTClientOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod method;

@property (nonatomic, weak) ARTLog *logger;
@property (art_nullable, nonatomic, readonly, strong) ARTTokenDetails *tokenDetails;
@property (nonatomic, readonly, assign) NSTimeInterval timeOffset;

@end

@interface ARTAuth (Private)

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions;
- (ARTTokenParams *)mergeParams:(ARTTokenParams *)customParams;

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params;
- (NSMutableURLRequest *)buildRequest:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params;

// Execute the received ARTTokenRequest
- (void)executeTokenRequest:(ARTTokenRequest *)tokenRequest callback:(void (^)(ARTTokenDetails *__art_nullable tokenDetails, NSError *__art_nullable error))callback;

// CONNECTED ProtocolMessage may contain a clientId
- (void)setProtocolClientId:(NSString *)clientId;

// Discard the cached local clock offset
- (void)discardTimeOffset;

// Private TokenDetails setter for testing only
- (void)setTokenDetails:(ARTTokenDetails *)tokenDetails;

// Private TimeOffset setter for testing only
- (void)setTimeOffset:(NSTimeInterval)offset;

@end

ART_ASSUME_NONNULL_END
