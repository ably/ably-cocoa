#import <Ably/ARTPaginatedResult.h>

@class ARTRestInternal;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPaginatedResult<ItemType> ()

@property (nonatomic, readonly) ARTRestInternal *rest;
@property (nonatomic, readonly) dispatch_queue_t userQueue;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) NSURLRequest *relFirst;
@property (nonatomic, readonly) NSURLRequest *relCurrent;
@property (nonatomic, readonly) NSURLRequest *relNext;

typedef NSArray<ItemType> *_Nullable(^ARTPaginatedResultResponseProcessor)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable *_Nullable);

- (instancetype)initWithItems:(NSArray *)items
                         rest:(ARTRestInternal *)rest
                     relFirst:(NSURLRequest *)relFirst
                   relCurrent:(NSURLRequest *)relCurrent
                      relNext:(NSURLRequest *)relNext
            responseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
             wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                       logger:(ARTInternalLog *)logger NS_DESIGNATED_INITIALIZER;

+ (void)executePaginated:(ARTRestInternal *)rest
             withRequest:(NSURLRequest *)request
    andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
        wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                  logger:(ARTInternalLog *)logger
                callback:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
