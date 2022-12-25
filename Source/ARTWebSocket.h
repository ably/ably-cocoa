#ifndef ARTWebSocket_h
#define ARTWebSocket_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTLog;
@protocol ARTWebSocketDelegate;

typedef NS_ENUM(NSInteger, ARTWebSocketState) {
    ARTWebSocketStateConnecting   = 0,
    ARTWebSocketStateOpened       = 1,
    ARTWebSocketStateClosing      = 2,
    ARTWebSocketStateClosed       = 3,
};

/**
 * Describes an object that lets you connect, send and receive data to a remote web socket.
 */
@protocol ARTWebSocket <NSObject>

/**
 * The delegate of the web socket.
 *
 * The web socket delegate is notified on all state changes that happen to the web socket.
 */
@property (nullable, nonatomic, weak) id<ARTWebSocketDelegate> delegate;

/**
 * A dispatch queue for scheduling the delegate calls.
 *
 * If `nil`, the socket uses main queue for performing all delegate method calls.
 */
@property (nullable, nonatomic, strong) dispatch_queue_t delegateDispatchQueue;

/**
 * Current ready state of the socket.
 *
 * This property is thread-safe.
 */
@property (atomic, assign, readonly) ARTWebSocketState readyState;

/**
 * Initializes a web socket with a given `NSURLRequest`.
 *
 * @param request A request to initialize with.
 * @param logger An `ARTLog` object to initialize with.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)request logger:(nullable ARTLog *)logger;

/**
 * Opens web socket, which will trigger connection, authentication and start receiving/sending events.
 */
- (void)open;

/**
 * Closes a web socket using a given code and reason.
 *
 * @param code Code to close the socket with.
 * @param reason Reason to send to the server or `nil`.
 */
- (void)closeWithCode:(NSInteger)code reason:(nullable NSString *)reason;

/**
 * Sends a UTF-8 string or a binary data to the server.
 *
 * @param message UTF-8 `NSString` or `NSData` to send.
 */
- (void)send:(id)message;

@end

/**
 * Describes methods that `ARTWebSocket` objects call on their delegates to handle status and messsage events.
 */
@protocol ARTWebSocketDelegate <NSObject>

/**
 * Called when a given web socket was open and authenticated.
 *
 * @param webSocket An instance of an `ARTWebSocket` conforming object that was open.
 */
- (void)webSocketDidOpen:(id<ARTWebSocket>)webSocket;

/**
 * Called when a given web socket was closed.
 *
 * @param webSocket An instance of an `ARTWebSocket` conforming object that was closed.
 * @param code Code reported by the server.
 * @param reason Reason in a form of a string that was reported by the server or `nil`.
 * @param wasClean Boolean value indicating whether a socket was closed in a clean state.
 */
- (void)webSocket:(id<ARTWebSocket>)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean;

/**
 * Called when a given web socket encountered an error.
 *
 * @param webSocket An instance of an `ARTWebSocket` conforming object that failed with an error.
 * @param error An instance of `NSError`.
 */
- (void)webSocket:(id<ARTWebSocket>)webSocket didFailWithError:(NSError *)error;

/**
 * Called when any message was received from a web socket.
 *
 * @param webSocket An instance of an `ARTWebSocket` conforming object that received a message.
 * @param message Received message. Either a `NSString` or `NSData`.
 */
- (void)webSocket:(id<ARTWebSocket>)webSocket didReceiveMessage:(id)message;

@end

NS_ASSUME_NONNULL_END

#endif /* ARTWebSocket_h */
