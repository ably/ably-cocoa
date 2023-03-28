@import Foundation;
#import <Ably/ARTLog.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Version2LogHandler)
// TODO document, explain that this is going to become the public interface in next version, here there'll be rich information like timestamps, tags, components. we will want to do research into what would be a good thing to put here — compare to e.g Apple’s swift-log
@protocol ARTVersion2LogHandler

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;

@end

NS_ASSUME_NONNULL_END
