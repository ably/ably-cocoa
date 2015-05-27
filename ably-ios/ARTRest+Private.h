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

/**
 ARTRest private methods that are used for whitebox testing.
 */

typedef NS_ENUM(NSUInteger, ARTAuthentication) {
    ARTAuthenticationOff,
    ARTAuthenticationOn,
    ARTAuthenticationUseBasic
};

@interface ARTRest (Private)

@property (readonly, strong, nonatomic) id<ARTEncoder> defaultEncoder;
@property (readonly, strong, nonatomic) ARTAuth *auth;
@property (readwrite, strong, nonatomic) NSURL *baseUrl;

- (NSString *)formatQueryParams:(NSDictionary *)queryParams;

- (NSURL *)resolveUrl:(NSString *)relUrl;
- (NSURL *)resolveUrl:(NSString *)relUrl queryParams:(NSDictionary *)queryParams;

- (id<ARTCancellable>)get:(NSString *)relUrl authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;
- (id<ARTCancellable>)get:(NSString *)relUrl headers:(NSDictionary *)headers authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;
- (id<ARTCancellable>)post:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb;

- (id<ARTCancellable>)withAuthHeadersUseBasic:(BOOL) useBasic cb:(id<ARTCancellable>(^)(NSDictionary *))cb;
- (id<ARTCancellable>)withAuthHeaders:(id<ARTCancellable>(^)(NSDictionary *authHeaders))cb;
- (id<ARTCancellable>)withAuthParams:(id<ARTCancellable>(^)(NSDictionary *authParams))cb;

-(id<ARTCancellable>) postTestStats:(NSArray *) stats cb:(void(^)(ARTStatus * status)) cb;


@end
