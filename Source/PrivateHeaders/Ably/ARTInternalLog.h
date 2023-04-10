@import Foundation;
#import <Ably/ARTLog.h>

@protocol ARTVersion2Log;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(InternalLog)
/**
 `ARTInternalLog` is the logging class used internally by the SDK. It’s responsible for receiving log messages from SDK components, performing additional processing on these messages, and forwarding the result to an object conforming to the `ARTVersion2Log` protocol.

 This class exists to give internal SDK components access to a rich and useful logging interface, whilst minimising the complexity (and hence the implementation burden for users of the SDK) of the `ARTVersion2Log` protocol. It also allows us to evolve the logging interface used internally without introducing breaking changes for users of the SDK.

 The initial interface of `ARTInternalLog` more or less mirrors that of the `ARTLog` class, for compatibility with existing internal SDK code. However, it will evolve as we gather requirements for the information logged by the SDK — see issues #1623 and #1624.

 - Note: It would be great if we could make `ARTInternalLog` a protocol (with a default implementation) instead of a class, since this would make it easier to test the logging behaviour of the SDK. However, since its interface currently makes heavy use of variadic Objective-C methods, which cannot be represented in Swift, we would be unable to write mocks for this protocol in our Swift test suite. As the `ARTInternalLog` interface evolves we may end up removing these variadic methods, in which case we can reconsider.
 */
@interface ARTInternalLog: NSObject

/**
 Creates a logger which forwards its generated messages to the given logger.
 */
- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;
- (void)logWithError:(ARTErrorInfo *)error;

@property (nonatomic, assign) ARTLogLevel logLevel;

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
