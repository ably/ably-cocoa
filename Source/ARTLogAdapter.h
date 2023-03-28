@import Foundation;

#import "ARTVersion2LogHandler.h"

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

// TODO document and test
@interface ARTLogAdapter: NSObject <ARTVersion2LogHandler>

- (instancetype)initWithLogHandler:(ARTLog *)logHandler;

@end

NS_ASSUME_NONNULL_END
