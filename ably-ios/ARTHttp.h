//
//  ARTHttp.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTTypes.h"


@interface ARTHttpError : NSObject
@property (strong, nonatomic) NSString *message;
@property (assign, nonatomic) int statusCode;
@property (assign, nonatomic) int code;
@end


@interface ARTHttpRequest : NSObject

@property (readonly, strong, nonatomic) NSString *method;
@property (readonly, strong, nonatomic) NSURL *url;
@property (readonly, strong, nonatomic) NSDictionary *headers;
@property (readonly, strong, nonatomic) NSData *body;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithMethod:(NSString *)method url:(NSURL *)url headers:(NSDictionary *)headers body:(NSData *)body;
- (ARTHttpRequest *)requestWithRelativeUrl:(NSString *)relUrl;

@end

@interface ARTHttpResponse : NSObject

@property (readonly, assign, nonatomic) int status;
@property (readonly, strong, nonatomic) NSDictionary *headers;
@property (readonly, strong, nonatomic) NSData *body;

- (instancetype)init;
- (instancetype)initWithStatus:(int)status headers:(NSDictionary *)headers body:(NSData *)body;

+ (instancetype)response;
+ (instancetype)responseWithStatus:(int)status headers:(NSDictionary *)headers body:(NSData *)body;

- (NSString *)contentType;
- (NSDictionary *)links;

@end

@interface ARTHttp : NSObject

- (instancetype)init;

typedef void (^ARTHttpCb)(ARTHttpResponse *response);
- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method url:(NSURL *)url headers:(NSDictionary *)headers body:(NSData *)body cb:(ARTHttpCb)cb;
- (id<ARTCancellable>)makeRequest:(ARTHttpRequest *)req cb:(ARTHttpCb)cb;

@end
