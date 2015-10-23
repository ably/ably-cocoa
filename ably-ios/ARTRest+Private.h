//
//  ARTRest+Private.h
//  ably-ios
//
//  Created by Jason Choy on 21/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest.h"

@protocol ARTEncoder;
@protocol ARTHTTPExecutor;

ART_ASSUME_NONNULL_BEGIN

/// ARTRest private methods that are used for whitebox testing
@interface ARTRest (Private)

@property (readonly, strong, nonatomic) id<ARTEncoder> defaultEncoder;
@property (readonly, strong, nonatomic) NSString *defaultEncoding; //Content-Type
@property (readonly, strong, nonatomic) NSDictionary *encoders;

@property (nonatomic, strong) id<ARTHTTPExecutor> httpExecutor;
@property (readonly, nonatomic, assign) Class channelClass;

@property (nonatomic, strong) NSURL *baseUrl;

// FIXME: used for Realtime. Review because ARTRealtime does not use ARTRest as base class
- (NSString *)formatQueryParams:(NSDictionary *)queryParams;

// MARK: ARTHTTPExecutor

- (void)executeRequest:(NSMutableURLRequest *)request completion:(ARTHttpRequestCallback)callback;

// MARK: Internal

- (void)executeRequest:(NSMutableURLRequest *)request withAuthOption:(ARTAuthentication)authOption completion:(ARTHttpRequestCallback)callback;

- (void)calculateAuthorization:(ARTAuthMethod)method completion:(void (^)(NSString *__art_nonnull authorization, NSError *__art_nullable error))callback;

- (id<ARTCancellable>)postTestStats:(NSArray *)stats cb:(void(^)(ARTStatus * status)) cb;

@end

ART_ASSUME_NONNULL_END
