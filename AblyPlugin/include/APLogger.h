@import Foundation;
#import "ARTLog.h"

NS_ASSUME_NONNULL_BEGIN

/// A logger to be used by plugins. Provides a stable API (that is, one which will not introduce backwards-incompatible changes within a given major version of ably-cocoa).
NS_SWIFT_NAME(Logger)
NS_SWIFT_SENDABLE
@protocol APLogger <NSObject>

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSInteger)line;

@end

NS_ASSUME_NONNULL_END
