#import <Ably/ARTHTTPPaginatedResponse.h>

#import <Ably/ARTPaginatedResult+Private.h>

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTHTTPPaginatedResponse ()

@property (nonatomic) NSHTTPURLResponse *response;

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response
                           items:(NSArray *)items
                            rest:(ARTRestInternal *)rest
                        relFirst:(NSMutableURLRequest *)relFirst
                      relCurrent:(NSMutableURLRequest *)relCurrent
                         relNext:(NSMutableURLRequest *)relNext
               responseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
                          logger:(ARTInternalLog *)logger;

+ (void)executePaginated:(ARTRestInternal *)rest
             withRequest:(NSMutableURLRequest *)request
    andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
                callback:(void (^)(ARTPaginatedResult * _Nullable, ARTErrorInfo * _Nullable))callback UNAVAILABLE_ATTRIBUTE;

+ (void)executePaginated:(ARTRestInternal *)rest
             withRequest:(NSMutableURLRequest *)request
                  logger:(ARTInternalLog *)logger
                callback:(ARTHTTPPaginatedCallback)callback;

@end

NS_ASSUME_NONNULL_END
