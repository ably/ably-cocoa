//
//  ARTRest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest+Private.h"

#import "ARTChannel+Private.h"
#import "ARTChannelCollection.h"
#import "ARTDataQuery+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTAuth.h"
#import "ARTHttp.h"
#import "ARTEncoder.h"
#import "ARTJsonEncoder.h"
#import "ARTMessage.h"
#import "ARTPresence.h"
#import "ARTPresenceMessage.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"
#import "ARTDefault.h"
#import "ARTStats.h"
#import "ARTFallback.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRestChannel.h"

@interface ARTRest ()

@property (nonatomic, strong) NSURL *baseUrl;
@property (nonatomic, strong) id<ARTHTTPExecutor> httpExecutor;
@property (readonly, nonatomic, assign) Class channelClass;

@property (readonly, strong, nonatomic) ARTHttp *http;
@property (strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) NSDictionary *encoders;
@property (readonly, strong, nonatomic) NSString *defaultEncoding; //Content-Type
@property (readwrite, assign, nonatomic) int fallbackCount;

@end

@implementation ARTRest

- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRest: No options provided");
        _options = options;
        _baseUrl = [options restUrl];
        
        if (logger) {
            _logger = logger;
        }
        else {
            _logger = [[ARTLog alloc] init];
        }
        
        _http = [[ARTHttp alloc] init];
        _httpExecutor = _http;
        _httpExecutor.logger = _logger;
        _channelClass = [ARTRestChannel class];
        
        id<ARTEncoder> defaultEncoder = [[ARTJsonEncoder alloc] init];
        _encoders = @{ [defaultEncoder mimeType]: defaultEncoder };
        _defaultEncoding = [defaultEncoder mimeType];
        _fallbackCount = 0;
        
        _auth = [[ARTAuth alloc] init:self withOptions:options];
        _channels = [[ARTChannelCollection alloc] initWithRest:self];
    }
    return self;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    return [self initWithLogger:[[ARTLog alloc] init] andOptions:options];
}

- (instancetype)initWithKey:(NSString *) key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (void)executeRequest:(NSMutableURLRequest *)request callback:(void (^)(NSHTTPURLResponse *, NSData *, NSError *))callback {
    request.URL = [NSURL URLWithString:request.URL.relativeString relativeToURL:self.baseUrl];
    
    NSString *accept = [[_encoders.allValues valueForKeyPath:@"mimeType"] componentsJoinedByString:@","];
    [request setValue:accept forHTTPHeaderField:@"Accept"];
    
    [self calculateAuthorization:^(NSString *authorization, NSError *error) {
        if (error) {
            callback(nil, nil, error);
        } else {
            // RFC7235
            [request setValue:authorization forHTTPHeaderField:@"Authorization"];
            
            [self.httpExecutor executeRequest:request callback:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                if (response.statusCode >= 400) {
                    NSError *error = [self->_encoders[response.MIMEType] decodeError:data];
                    if (error.code == 40140) {
                        // TODO: request token or error if no token information
                        NSAssert(false, @"Request token or error if no token information");
                    } else {
                        callback(nil, nil, error);
                    }
                } else {
                    callback(response, data, error);
                }
            }];
        }
    }];
}

- (void)calculateAuthorization:(void (^)(NSString *authorization, NSError *error))callback {
    // FIXME: use encoder
    if (self.auth.method == ARTAuthMethodBasic) {
        // Include key Base64 encoded in an Authorization header (RFC7235)
        NSData *keyData = [self.options.key dataUsingEncoding:NSUTF8StringEncoding];
        NSString *keyBase64 = [keyData base64EncodedStringWithOptions:0]; //NSDataBase64EncodingEndLineWithCarriageReturn
        callback([NSString stringWithFormat:@"Basic %@", keyBase64], nil);
    }
    else {
        // TODO: Reuse
        NSData *keyData = [self.options.token dataUsingEncoding:NSUTF8StringEncoding];
        NSString *keyBase64 = [keyData base64EncodedStringWithOptions:0];
        callback([NSString stringWithFormat:@"Bearer %@", keyBase64], nil);
    }
}

- (void)time:(void(^)(NSDate *time, NSError *error))callback {
    NSURL *requestUrl = [NSURL URLWithString:@"/time" relativeToURL:self.baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"GET";
    NSString *accept = [[_encoders.allValues valueForKeyPath:@"mimeType"] componentsJoinedByString:@","];
    [request setValue:accept forHTTPHeaderField:@"Accept"];
    
    [self.httpExecutor executeRequest:request callback:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode >= 400) {
            callback(nil, [self->_encoders[response.MIMEType] decodeError:data]);
        } else {
            callback([self->_encoders[response.MIMEType] decodeTime:data], nil);
        }
    }];
}

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb {
    [self.http makeRequestWithMethod:@"GET" url:[NSURL URLWithString:@"http://internet-up.ably-realtime.com/is-the-internet-up.txt"] headers:nil body:nil cb:^(ARTHttpResponse *response) {
        NSString * str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
        cb(response.status == 200 && [str isEqualToString:@"yes\n"]);
    }];
    return nil;
}

- (void)stats:(ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult *, NSError *))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);
    
    // FIXME:
    /*
    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:@"/stats"];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[requestUrl URLRelativeToURL:self.baseUrl]];
    
    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [self.encoders objectForKey:response.MIMEType];
        return [encoder decodeStats:data];
    };
    
    [ARTPaginatedResult executePaginatedRequest:request executor:self responseProcessor:responseProcessor callback:callback];
     */
}

- (id<ARTEncoder>)defaultEncoder {
    return self.encoders[self.defaultEncoding];
}

@end
