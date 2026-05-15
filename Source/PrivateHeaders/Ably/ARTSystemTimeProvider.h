#import <Foundation/Foundation.h>
#import "ARTTimeProvider.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The default `ARTTimeProvider` implementation; backed by the system wall clock, the system continuous clock, and `artDispatchScheduled`.
 */
@interface ARTSystemTimeProvider : NSObject <ARTTimeProvider>
@end

NS_ASSUME_NONNULL_END
