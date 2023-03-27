@import Foundation;
#import <Ably/ARTLog.h>

@protocol ARTVersion2LogHandler;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(InternalLogHandler)
// TODO explain that this can't easily be a protocol because of the -verbose etc methods, which the existing code relies heavily on but which is not mockable in Swift because of their variadic nature

// TODO explain this interface can change as we like; currently it just matches that of ARTLog so that we don't need to change all of the code — but that's a good thing about having this separation from ARTVersion2LogHandler so that things that are convenient for the code don't need to pollute that protocol
@interface ARTInternalLogHandler: NSObject

- (instancetype)initWithLogHandler:(id<ARTVersion2LogHandler>)logHandler NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Copied from ARTLog
- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;
- (void)logWithError:(ARTErrorInfo *)error;

@property (nonatomic, assign) ARTLogLevel logLevel;

// TODO what if people have made their own implementation of these things? then we can't just call through

// Copied from ARTLog (Shorthand)
- (void)verbose:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)verbose:(const char *)fileName line:(NSUInteger)line message:(NSString *)message, ... NS_FORMAT_FUNCTION(3,4);
- (void)debug:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)debug:(const char *)fileName line:(NSUInteger)line message:(NSString *)message, ... NS_FORMAT_FUNCTION(3,4);
- (void)info:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)warn:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)error:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end

NS_ASSUME_NONNULL_END
