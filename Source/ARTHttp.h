//
//  ARTHttp.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"

@class ARTErrorInfo;

ART_ASSUME_NONNULL_BEGIN

@protocol ARTHTTPExecutor

@property (nonatomic, weak) ARTLog *logger;

- (void)executeRequest:(NSMutableURLRequest *)request completion:(art_nullable void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback;

@end

@interface ARTHttpRequest : NSObject

@property (readonly, strong, nonatomic) NSString *method;
@property (readonly, strong, nonatomic) NSURL *url;
@property (art_nullable, readonly, strong, nonatomic) NSDictionary *headers;
@property (art_nullable, readonly, strong, nonatomic) NSData *body;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithMethod:(NSString *)method url:(NSURL *)url headers:(art_nullable NSDictionary *)headers body:(art_nullable NSData *)body;
- (ARTHttpRequest *)requestWithRelativeUrl:(NSString *)relUrl;

@end

@interface ARTHttpResponse : NSObject

@property (readonly, assign, nonatomic) int status;
@property (readwrite, strong, nonatomic) ARTErrorInfo *error;
@property (art_nullable, readonly, strong, nonatomic) NSDictionary *headers;
@property (art_nullable, readonly, strong, nonatomic) NSData *body;

- (instancetype)init;
- (instancetype)initWithStatus:(int)status headers:(art_nullable NSDictionary *)headers body:(art_nullable NSData *)body;

+ (instancetype)response;
+ (instancetype)responseWithStatus:(int)status headers:(art_nullable NSDictionary *)headers body:(art_nullable NSData *)body;

- (NSString *)contentType;
- (NSDictionary *)links;

@end

@interface ARTHttp : NSObject<ARTHTTPExecutor>
{
    
}

@property (nonatomic, weak) ARTLog *logger;

- (instancetype)init;

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method url:(NSURL *)url headers:(art_nullable NSDictionary *)headers body:(art_nullable NSData *)body callback:(void (^)(ARTHttpResponse *))cb;


@end

ART_ASSUME_NONNULL_END
