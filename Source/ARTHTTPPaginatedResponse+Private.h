//
//  ARTHTTPPaginatedResponse+Private.h
//  Ably
//
//

#import <Ably/ARTHTTPPaginatedResponse.h>

#import <Ably/ARTPaginatedResult+Private.h>

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTHTTPPaginatedResponse ()

@property (nonatomic, strong) NSHTTPURLResponse *response;

+ (void)executePaginated:(ARTRestInternal *)rest
             withRequest:(NSMutableURLRequest *)request
    andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
                callback:(void (^)(ARTPaginatedResult * _Nullable, ARTErrorInfo * _Nullable))callback UNAVAILABLE_ATTRIBUTE;

+ (void)executePaginated:(ARTRestInternal *)rest
             withRequest:(NSMutableURLRequest *)request
                callback:(ARTHTTPPaginatedCallback)callback;

@end

NS_ASSUME_NONNULL_END
