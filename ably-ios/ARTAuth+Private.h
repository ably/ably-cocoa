//
//  ARTAuth+Private.h
//  ably
//
//  Created by Ricardo Pereira on 03/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuth.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTAuth (Private)

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions;
- (ARTTokenParams *)mergeParams:(ARTTokenParams *)customParams;

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params;
- (NSMutableURLRequest *)buildRequest:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params;

// Execute the received ARTTokenRequest
- (void)executeTokenRequest:(ARTTokenRequest *)tokenRequest callback:(void (^)(ARTTokenDetails *__art_nullable tokenDetails, NSError *__art_nullable error))callback;

// CONNECTED ProtocolMessage may contain a clientId
- (void)setProtocolClientId:(NSString *)clientId;

@end

ART_ASSUME_NONNULL_END
