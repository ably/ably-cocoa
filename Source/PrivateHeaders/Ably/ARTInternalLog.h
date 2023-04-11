@import Foundation;
#import <Ably/ARTLog.h>

@protocol ARTInternalLogBackend;
@protocol ARTVersion2Log;

/**
 Logs a message to a given instance of `ARTInternalLog`. The `ARTLogVerbose` etc macros wrap this; favour using those.

 - Parameters:
   - _logger: An instance of `ARTInternalLog`.
   - _level: An `ARTLogLevel` value.
   - _format: An NSString format string, followed by any arguments to interpolate in the format string.
 */
#define ARTLog(_logger, _level, _format, ...) [_logger logWithLevel:_level file:__FILE__ line:__LINE__ format:_format, ##__VA_ARGS__]

#define ARTLogVerbose(logger, format, ...) ARTLog(logger, ARTLogLevelVerbose, format, ##__VA_ARGS__)
#define ARTLogDebug(logger, format, ...) ARTLog(logger, ARTLogLevelDebug, format, ##__VA_ARGS__)
#define ARTLogInfo(logger, format, ...) ARTLog(logger, ARTLogLevelInfo, format, ##__VA_ARGS__)
#define ARTLogWarn(logger, format, ...) ARTLog(logger, ARTLogLevelWarn, format, ##__VA_ARGS__)
#define ARTLogError(logger, format, ...) ARTLog(logger, ARTLogLevelError, format, ##__VA_ARGS__)

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(InternalLog)
/**
 `ARTInternalLog` is the logging class used internally by the SDK. It provides a thin wrapper over `ARTInternalLogBackend`, providing variadic versions of that protocol’s methods.

 - Note: It would be great if we could make `ARTInternalLog` a protocol (with a default implementation) instead of a class, since this would make it easier to test the logging behaviour of the SDK. However, since its interface currently makes heavy use of variadic Objective-C methods, which cannot be represented in Swift, we would be unable to write mocks for this protocol in our Swift test suite. As the `ARTInternalLog` interface evolves we may end up removing these variadic methods, in which case we can reconsider.
 */
@interface ARTInternalLog: NSObject

/**
 Creates a logger which forwards its generated messages to the given logger.
 */
- (instancetype)initWithBackend:(id<ARTInternalLogBackend>)backend NS_DESIGNATED_INITIALIZER;
/**
 A convenience initializer which creates a logger whose backend is an instance of `ARTDefaultInternalLogBackend` wrapping the given logger.
 */
- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger;
- (instancetype)init NS_UNAVAILABLE;

// This method passes the arguments through to the logger’s backend. It is not directly used by the internals of the SDK, but we need it because some of our Swift tests (which can’t access the variadic method below) want to be able to call a logging method on an instance of `ARTInternalLog`.
- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSInteger)line;

// This method should not be called directly — it is for use by the ARTLog* macros. It is tested via the tests of the macros.
- (void)logWithLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSUInteger)line format:(NSString *)format, ...  NS_FORMAT_FUNCTION(4,5);

@property (nonatomic, assign) ARTLogLevel logLevel;

@end

NS_ASSUME_NONNULL_END
