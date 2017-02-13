//
//  ARTRest+Private.h
//  ably-ios
//
//  Created by Jason Choy on 21/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest.h"
#import "ARTHttp.h"

@protocol ARTEncoder;
@protocol ARTHTTPExecutor;

ART_ASSUME_NONNULL_BEGIN

/// ARTRest private methods that are used internally and for whitebox testing
@interface ARTRest () <ARTHTTPAuthenticatedExecutor>

@property (nonatomic, strong, readonly) ARTClientOptions *options;
@property (readonly, strong, nonatomic) __GENERIC(id, ARTEncoder) defaultEncoder;
@property (readonly, strong, nonatomic) NSString *defaultEncoding; //Content-Type
@property (readonly, strong, nonatomic) NSDictionary *encoders;
@property (readwrite, strong, nonatomic, art_nullable) NSString *prioritizedHost;

@property (nonatomic, strong) id<ARTHTTPExecutor> httpExecutor;

@property (nonatomic, readonly, getter=getBaseUrl) NSURL *baseUrl;

@property (readonly, strong, nonatomic) ARTHttp *http;
@property (strong, nonatomic) ARTAuth *auth;
@property (readwrite, assign, nonatomic) int fallbackCount;

// MARK: Internal

- (void)prepareAuthorisationHeader:(ARTAuthMethod)method completion:(void (^)(NSString *__art_nonnull authorization, NSError *__art_nullable error))callback;

- (id<ARTCancellable>)internetIsUp:(void (^)(BOOL isUp))cb;

@end

ART_ASSUME_NONNULL_END
