@import Foundation;

#import "ARTVersion2Log.h"

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

// TODO document and test
@interface ARTLogAdapter: NSObject <ARTVersion2Log>

- (instancetype)initWithLogger:(ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
