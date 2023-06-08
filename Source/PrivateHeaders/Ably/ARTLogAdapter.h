@import Foundation;

#import <Ably/ARTVersion2Log.h>

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
 `ARTLogAdapter` implements this `ARTVersion2Log` protocol requirement by forwarding the setter and getter calls to its underlying `ARTLog` instance.
 */
@property (nonatomic) ARTLogLevel logLevel;

@end

NS_ASSUME_NONNULL_END
