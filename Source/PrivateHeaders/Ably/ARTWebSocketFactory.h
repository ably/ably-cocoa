@import Foundation;

@protocol ARTWebSocket;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

/**
 A factory for creating an `ARTWebSocket` object.
 */
NS_SWIFT_NAME(WebSocketFactory)
@protocol ARTWebSocketFactory

- (id<ARTWebSocket>)createWebSocketWithURLRequest:(NSURLRequest *)request logger:(nullable ARTInternalLog *)logger;

@end

/**
 The implementation of `ARTWebSocketFactory` that should be used in non-test code.
 */
NS_SWIFT_NAME(DefaultWebSocketFactory)
@interface ARTDefaultWebSocketFactory: NSObject <ARTWebSocketFactory>
@end

NS_ASSUME_NONNULL_END
