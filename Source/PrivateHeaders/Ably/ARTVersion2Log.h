@import Foundation;
#import <Ably/ARTLog.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `ARTVersion2Log` protocol represents a logger object that handles log output emitted by the SDK. It will be renamed `ARTLog` in the next major release of the SDK (replacing the existing class), at which point users of the SDK will need to provide an implementation of this protocol if they wish to replace the SDK’s default logger.

 The initial interface of `ARTVersion2Log` is based on that of the `ARTLog` class. However, its design will evolve as we gather further information about the following things:

 1. The SDK’s internal logging requirements — that is, what kind of data does the SDK wish to be able to log, in order to make its emitted logs maximally useful to those who read them? For example, information about which component of the SDK emitted a log message, or tags that categorise its emitted log messages.

 2. Users’ logging output requirements. That is, what is the most useful way of representing the logging data emitted by the SDK? How can we make it easy to integrate our SDK with commonly-used logging solutions, such as Apple’s swift-log? How can we make it easy to integrate into Ably’s other products, such as the Asset Tracking SDK?
 */
NS_SWIFT_NAME(Version2Log)
@protocol ARTVersion2Log

@property (nonatomic, assign) ARTLogLevel logLevel;

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;

- (void)logWithError:(ARTErrorInfo *)error;

@end

NS_ASSUME_NONNULL_END
