#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTHttpResponse;
@class ARTClientOptions;

@interface ARTFallback : NSObject

/**
 Init with fallback hosts array.
 */
- (instancetype)initWithFallbackHosts:(nullable NSArray<NSString *> *)fallbackHosts shuffleArray:(void (^)(NSMutableArray *))shuffleArray;
- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a random fallback host, returns null when all hosts have been popped.
 */
- (nullable NSString *)popFallbackHost;

/**
  Returns true if all hosts have been popped without popping one.
 */
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END
