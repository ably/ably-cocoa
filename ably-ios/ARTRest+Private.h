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

typedef NS_ENUM(NSUInteger, ARTAuthentication) {
    ARTAuthenticationOff,
    ARTAuthenticationOn,
    ARTAuthenticationUseBasic
};

/// ARTRest private methods that are used for whitebox testing
@interface ARTRest (Private)

@property (readonly, strong, nonatomic) id<ARTEncoder> defaultEncoder;
@property (readonly, strong, nonatomic) NSString *defaultEncoding; //Content-Type

@property (nonatomic, strong) id<ARTHTTPExecutor> httpExecutor;
@property (readonly, nonatomic, assign) Class channelClass;

@property (nonatomic, strong) NSURL *baseUrl;

- (NSURL *)getBaseURL;
- (NSString *)formatQueryParams:(NSDictionary *)queryParams;

- (NSURL *)resolveUrl:(NSString *)relUrl;
- (NSURL *)resolveUrl:(NSString *)relUrl queryParams:(NSDictionary *)queryParams;

- (id<ARTCancellable>)get:(NSString *)relUrl authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;
- (id<ARTCancellable>)get:(NSString *)relUrl headers:(NSDictionary *)headers authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;

- (id<ARTCancellable>)post:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb;

- (void)executeRequest:(NSMutableURLRequest *)request callback:(void (^)(NSHTTPURLResponse *, NSData *, NSError *))callback;

- (id<ARTCancellable>)postTestStats:(NSArray *)stats cb:(void(^)(ARTStatus * status)) cb;

@end
