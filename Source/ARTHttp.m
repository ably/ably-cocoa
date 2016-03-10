//
//  ARTHttp.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTHttp.h"
#import "ARTURLSessionServerTrust.h"

@interface ARTHttp ()

@property (readonly, copy, nonatomic) NSURL *baseUrl;
@property (readonly, strong, nonatomic) ARTURLSessionServerTrust *urlSession;

@end

@interface ARTHttpRequestHandle : NSObject <ARTCancellable>

@property (readonly, nonatomic, strong) NSURLSessionDataTask *dataTask;

- (instancetype)initWithDataTask:(NSURLSessionDataTask *)dataTask;
+ (instancetype)requestHandleWithDataTask:(NSURLSessionDataTask *)dataTask;

@end


#pragma mark - ARTHttpRequest

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


#pragma mark - ARTHttpResponse

@implementation ARTHttpResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = 0;
        _error = nil;
        _headers = nil;
        _body = nil;
    }
    return self;
}

- (instancetype)initWithStatus:(int)status headers:(NSDictionary *)headers body:(NSData *)body {
    self = [super init];
    if (self) {
        _status = status;
        _error = nil;
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


#pragma mark - ARTHttpRequestHandle

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


#pragma mark - ARTHttp

@implementation ARTHttp

- (instancetype)init {
    self = [super init];
    if (self) {
        _urlSession = [[ARTURLSessionServerTrust alloc] init];
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

- (void)executeRequest:(NSMutableURLRequest *)request completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback {
    [self.logger debug:@"%@ %@", request.HTTPMethod, request.URL.absoluteString];
    [self.logger verbose:@"Headers %@", request.allHTTPHeaderFields];

    CFRunLoopRef currentRunloop = CFRunLoopGetCurrent();

    [_urlSession get:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        CFRunLoopPerformBlock(currentRunloop, kCFRunLoopCommonModes, ^{
            if (error) {
                [self.logger error:@"%@ %@: error %@", request.HTTPMethod, request.URL.absoluteString, error];
            } else {
                [self.logger debug:@"%@ %@: statusCode %ld", request.HTTPMethod, request.URL.absoluteString, (long)httpResponse.statusCode];
                [self.logger verbose:@"Headers %@", httpResponse.allHeaderFields];
                NSString *headerErrorMessage = httpResponse.allHeaderFields[@"X-Ably-ErrorMessage"];
                if (headerErrorMessage && ![headerErrorMessage isEqualToString:@""]) {
                    [self.logger warn:@"%@", headerErrorMessage];
                }
            }
            callback(httpResponse, data, error);
        });
        CFRunLoopWakeUp(currentRunloop);
    }];
}

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method url:(NSURL *)url headers:(NSDictionary *)headers body:(NSData *)body callback:(void (^)(ARTHttpResponse *))cb {
    return [self makeRequest:[[ARTHttpRequest alloc] initWithMethod:method url:url headers:headers body:body] callback:cb];
}

- (id<ARTCancellable>)makeRequest:(ARTHttpRequest *)artRequest callback:(void (^)(ARTHttpResponse *))cb {

    if(![artRequest.method isEqualToString:@"GET"] && ![artRequest.method isEqualToString:@"POST"]){
        [NSException raise:@"Http method must be GET or POST" format:@""];
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:artRequest.url];
    request.HTTPMethod = artRequest.method;
    [self.logger verbose:@"ARTHttp request URL is %@", artRequest.url];

    for (NSString *headerName in artRequest.headers) {
        NSString *headerValue = [artRequest.headers objectForKey:headerName];
        [request setValue:headerValue forHTTPHeaderField:headerName];
    }

    request.HTTPBody = artRequest.body;
    [self.logger debug:@"ARTHttp: makeRequest %@", [request allHTTPHeaderFields]];

    __block CFRunLoopRef rl = CFRunLoopGetCurrent();

    [self.urlSession get:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        [self.logger verbose:@"ARTHttp: Got response %@, err %@", response, error];
        
        if(error) {
            [self.logger error:@"ARTHttp receieved error: %@", error];
            cb([ARTHttpResponse responseWithStatus:500 headers:nil body:nil]);
        }
        else {
            if (httpResponse) {
                int status = (int)httpResponse.statusCode;
                [self.logger debug:@"ARTHttp response status is %d", status];
                [self.logger verbose:@"ARTHttp received response %@",[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
                
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
    }];
    return nil;
}

+ (NSDictionary *)getErrorDictionary {
    NSString * path =[[[[NSBundle bundleForClass: [self class]] resourcePath] stringByAppendingString:@"/"] stringByAppendingString:@"ably-common/protocol/errors.json"];
    NSString * errorsString =[NSString stringWithContentsOfFile:path
                                      encoding:NSUTF8StringEncoding
                                         error:NULL];
    NSData *data = [errorsString dataUsingEncoding:NSUTF8StringEncoding];
    NSError * error;
    NSDictionary * topLevel =[NSJSONSerialization JSONObjectWithData:data  options:NSJSONReadingMutableContainers error:&error];
    return  topLevel;
}

@end
