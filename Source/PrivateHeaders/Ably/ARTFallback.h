#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTHttpResponse;
@class ARTClientOptions;

/// :nodoc:
@interface ARTFallback : NSObject

/**
 Init with fallback hosts array.
 */
- (instancetype)initWithFallbackHosts:(nullable NSArray<NSString *> *)fallbackHosts shuffleArray:(void (^)(NSMutableArray *))shuffleArray;
- (instancetype)init NS_UNAVAILABLE;

/**
 returns a random fallback host, returns null when all hosts have been popped.
 */
- (nullable NSString *)popFallbackHost;

@end

NS_ASSUME_NONNULL_END
