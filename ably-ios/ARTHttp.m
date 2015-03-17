//
//  ARTHttp.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTHttp.h"

#include "ARTJsonEncoder.h" //TODO RM
@interface ARTHttp ()

@property (readonly, strong, nonatomic) NSURL *baseUrl;
@property (readonly, strong, nonatomic) NSURLSession *urlSession;

@end

@interface ARTHttpRequestHandle : NSObject <ARTCancellable>

@property (readonly, nonatomic, strong) NSURLSessionDataTask *dataTask;

- (instancetype)initWithDataTask:(NSURLSessionDataTask *)dataTask;
+ (instancetype)requestHandleWithDataTask:(NSURLSessionDataTask *)dataTask;

@end

@implementation ARTHttpRequest

- (instancetype)initWithMethod:(NSString *)method url:(NSURL *)url headers:(NSDictionary *)headers body:(NSData *)body {
    self = [super init];
    if (self) {
        _method = method;
        _url = url;
        _headers = headers;
        _body = body;
    }
    return self;
}

- (ARTHttpRequest *)requestWithRelativeUrl:(NSString *)relUrl {
    if (!relUrl) {
        return nil;
    }
    NSURL *newUrl = [NSURL URLWithString:relUrl relativeToURL:self.url];
    return [[ARTHttpRequest alloc] initWithMethod:self.method url:newUrl headers:self.headers body:self.body];
}

@end

@implementation ARTHttpResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = 0;
        _headers = nil;
        _body = nil;
    }
    return self;
}

- (instancetype)initWithStatus:(int)status headers:(NSDictionary *)headers body:(NSData *)body {
    self = [super init];
    if (self) {
        _status = status;
        _headers = headers;
        _body = body;
    }
    return self;
}

+ (instancetype)response {
    return [[ARTHttpResponse alloc] init];
}

+ (instancetype)responseWithStatus:(int)status headers:(NSDictionary *)headers body:(NSData *)body {
    return [[ARTHttpResponse alloc] initWithStatus:status headers:headers body:body];
}

- (NSString *)contentType {
    return [self.headers objectForKey:@"Content-Type"];
}

- (NSDictionary *)links {
    NSString *linkHeader = [self.headers objectForKey:@"Link"];
    if (!linkHeader) {
        return [NSDictionary dictionary];
    }

    NSMutableDictionary *links = [NSMutableDictionary dictionary];

    static NSRegularExpression *linkRegex = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\s*<([^>]*)>;\\s*rel=\"([^\"]*)\"" options:0 error:nil];
    });

    NSArray *matches = [linkRegex matchesInString:linkHeader options:0 range:NSMakeRange(0, linkHeader.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange linkUrlRange = [match rangeAtIndex:1];
        NSRange linkRelRange = [match rangeAtIndex:2];

        NSString *linkUrl = [linkHeader substringWithRange:linkUrlRange];
        NSString *linkRels = [linkHeader substringWithRange:linkRelRange];

        for (NSString *linkRel in [linkRels componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
            [links setObject:linkUrl forKey:linkRel];
        }
    }

    return links;
}

@end

@implementation ARTHttpRequestHandle

- (instancetype)initWithDataTask:(NSURLSessionDataTask *)dataTask {
    self = [super init];
    if (self) {
        _dataTask = dataTask;
    }
    return self;
}

+ (instancetype)requestHandleWithDataTask:(NSURLSessionDataTask *)dataTask {
    return [[ARTHttpRequestHandle alloc] initWithDataTask:dataTask];
}

- (void)cancel {
    [self.dataTask cancel];
}

@end

@implementation ARTHttp

- (instancetype)init {
    self = [super init];
    if (self) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _baseUrl = nil;
    }
    return self;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl {
    self = [self init];
    if (self) {
        _baseUrl = baseUrl;
    }
    return self;
}

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method url:(NSURL *)url headers:(NSDictionary *)headers body:(NSData *)body cb:(ARTHttpCb)cb {
    return [self makeRequest:[[ARTHttpRequest alloc] initWithMethod:method url:url headers:headers body:body] cb:cb];
}

- (id<ARTCancellable>)makeRequest:(ARTHttpRequest *)artRequest cb:(void (^)(ARTHttpResponse *))cb {
    NSAssert([artRequest.method isEqualToString:@"GET"] || [artRequest.method isEqualToString:@"POST"], @"Http method must be GET or POST");

    NSLog(@"req url is %@, method %@", artRequest.url, artRequest.method);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:artRequest.url];
    request.HTTPMethod = artRequest.method;

    
    for (NSString *headerName in artRequest.headers) {
        NSString *headerValue = [artRequest.headers objectForKey:headerName];
        [request setValue:headerValue forHTTPHeaderField:headerName];
    }

    request.HTTPBody = artRequest.body;
    NSLog(@"request is %@", request);
    NSLog(@"art request headers is %@", artRequest.headers);
    NSLog(@"TODO RM THIS");
    {
        
        if(artRequest.body) {
            ARTJsonEncoder * encoder =[[ARTJsonEncoder alloc] init];
        
            NSLog(@"decoded request is %@", [encoder decodeMessage:artRequest.body]);
            
        }
    }

    CFRunLoopRef rl = CFRunLoopGetCurrent();
    CFRetain(rl);
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"HTTP RESPONSE IN MAKE REQUEST, error %@, res %@", error, response);
        if(error) {
            //TODO send error?
            cb([ARTHttpResponse responseWithStatus:ARTStatusError headers:nil body:nil]);
        }
        else {
            if(artRequest.body) {
                ARTJsonEncoder * encoder =[[ARTJsonEncoder alloc] init];
                NSLog(@"decoded is %@", [encoder decodeMessage:data]);
                
            }
            if (httpResponse) {
                int status = (int)httpResponse.statusCode;
                NSLog(@"http resonse status is %d", status);
                CFRunLoopPerformBlock(rl, kCFRunLoopDefaultMode, ^{
                    cb([ARTHttpResponse responseWithStatus:status headers:httpResponse.allHeaderFields body:data]);
                });
            } else {
                CFRunLoopPerformBlock(rl, kCFRunLoopDefaultMode, ^{
                    cb([ARTHttpResponse response]);
                });
            }
        }
        CFRunLoopWakeUp(rl);
        CFRelease(rl);
    }];
    [task resume];
    return [ARTHttpRequestHandle requestHandleWithDataTask:task];
}

@end
