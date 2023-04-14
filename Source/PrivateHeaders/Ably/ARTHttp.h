#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTErrorInfo;
@class ARTClientOptions;
@class ARTInternalLog;

@protocol ARTEncoder;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@protocol ARTHTTPExecutor

- (nullable NSObject<ARTCancellable> *)executeRequest:(NSURLRequest *)request completion:(nullable ARTURLRequestCallback)callback;

@end

/// :nodoc:
@protocol ARTHTTPAuthenticatedExecutor <ARTHTTPExecutor>

- (ARTClientOptions *)options;

- (id<ARTEncoder>)defaultEncoder;

- (nullable NSObject<ARTCancellable> *)executeRequest:(NSMutableURLRequest *)request withAuthOption:(ARTAuthentication)authOption completion:(ARTURLRequestCallback)callback;

@end

/// :nodoc:
@interface ARTHttp : NSObject<ARTHTTPExecutor>

+ (void)setURLSessionClass:(Class)urlSessionClass;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithQueue:(dispatch_queue_t)queue logger:(ARTInternalLog *)logger;

@end

NS_ASSUME_NONNULL_END
