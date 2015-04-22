//
//  ARTRest+Private.h
//  ably-ios
//
//  Created by Jason Choy on 21/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTRest.h"
#import "ARTEncoder.h"

@interface ARTRest (Private)

@property (readonly, strong, nonatomic) id<ARTEncoder> defaultEncoder;

- (NSString *)formatQueryParams:(NSDictionary *)queryParams;


- (NSURL *)resolveUrl:(NSString *)relUrl;
- (NSURL *)resolveUrl:(NSString *)relUrl queryParams:(NSDictionary *)queryParams;

- (id<ARTCancellable>)get:(NSString *)relUrl authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;
- (id<ARTCancellable>)get:(NSString *)relUrl headers:(NSDictionary *)headers authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;
- (id<ARTCancellable>)post:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;

- (id<ARTCancellable>)withAuthHeaders:(id<ARTCancellable>(^)(NSDictionary *authHeaders))cb;
- (id<ARTCancellable>)withAuthParams:(id<ARTCancellable>(^)(NSDictionary *authParams))cb;

@end
