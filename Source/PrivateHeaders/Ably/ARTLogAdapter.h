@import Foundation;

#import "ARTVersion2Log.h"

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

/**
 `ARTLogAdapter` provides an implementation of `ARTVersion2Log` that writes all log messages to a given instance of `ARTLog`.

 The intention of this class is to allow us to maintain the public API of the SDK, which allows users to provide an `ARTLog` instance, whilst using `ARTVersion2Log` for logging inside the SDK. Upon the next major release of this library, when `ARTVersion2Log` will be renamed `ARTLog` and the current `ARTLog` will be removed, we can remove this class too.
 */
NS_SWIFT_NAME(LogAdapter)
@interface ARTLogAdapter: NSObject <ARTVersion2Log>

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an instance of `ARTLogAdapter` which wraps an underlying `ARTLog` instance.

 - Parameters:
    - logger: The `ARTLog` instance to wrap.
 */
- (instancetype)initWithLogger:(ARTLog *)logger;

/**
 `ARTLogAdapter` implements this `ARTVersion2Log` protocol requirement by calling the `-log:withMessage:` method on its underlying `ARTLog` instance.

 This implementation will necessarily change (becoming more complex) as we evolve the `ARTVersion2Log` protocol and hence the signature of this method. For example, if we add the ability to attach metadata to a log message, then this implementation will need to choose a way of representing that metadata as a string.

 - Note: `ARTLogAdapter` directly calls the underlying `ARTLog` instance’s `-log:withLevel:` method. It does not call any of the convenience methods in the "`ARTLog (Shorthand)`" category.
 */
- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;

/**
 `ARTLogAdapter` implements this `ARTVersion2Log` protocol requirement by forwarding the setter and getter calls to its underlying `ARTLog` instance.
 */
@property (nonatomic) ARTLogLevel logLevel;

@end

NS_ASSUME_NONNULL_END
