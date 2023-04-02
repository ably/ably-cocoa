//
// Copyright 2012 Square Inc.
// Portions Copyright (c) 2016-present, Facebook, Inc.
//
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ARTSRReadyState) {
    ARTSR_CONNECTING   = 0,
    ARTSR_OPEN         = 1,
    ARTSR_CLOSING      = 2,
    ARTSR_CLOSED       = 3,
};

typedef NS_ENUM(NSInteger, ARTSRStatusCode) {
    // 0-999: Reserved and not used.
    ARTSRStatusCodeNormal = 1000,
    ARTSRStatusCodeGoingAway = 1001,
    ARTSRStatusCodeProtocolError = 1002,
    ARTSRStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    ARTSRStatusNoStatusReceived = 1005,
    ARTSRStatusCodeAbnormal = 1006,
    ARTSRStatusCodeInvalidUTF8 = 1007,
    ARTSRStatusCodePolicyViolated = 1008,
    ARTSRStatusCodeMessageTooBig = 1009,
    ARTSRStatusCodeMissingExtension = 1010,
    ARTSRStatusCodeInternalError = 1011,
    ARTSRStatusCodeServiceRestart = 1012,
    ARTSRStatusCodeTryAgainLater = 1013,
    // 1014: Reserved for future use by the WebSocket standard.
    ARTSRStatusCodeTLSHandshake = 1015,
    // 1016-1999: Reserved for future use by the WebSocket standard.
    // 2000-2999: Reserved for use by WebSocket extensions.
    // 3000-3999: Available for use by libraries and frameworks. May not be used by applications. Available for registration at the IANA via first-come, first-serve.
    // 4000-4999: Available for use by applications.
};

@class ARTSRWebSocket;
@class ARTSRSecurityPolicy;
@class ARTLog;

/**
 Error domain used for errors reported by ARTSRWebSocket.
 */
extern NSString *const ARTSRWebSocketErrorDomain;

/**
 Key used for HTTP status code if bad response was received from the server.
 */
extern NSString *const ARTSRHTTPResponseErrorKey;

@protocol ARTSRWebSocketDelegate;

///--------------------------------------
#pragma mark - ARTSRWebSocket
///--------------------------------------

/**
 A `ARTSRWebSocket` object lets you connect, send and receive data to a remote Web Socket.
 */
@interface ARTSRWebSocket : NSObject <NSStreamDelegate>

/**
 The delegate of the web socket.

 The web socket delegate is notified on all state changes that happen to the web socket.
 */
@property (nonatomic, weak) id <ARTSRWebSocketDelegate> delegate;

/**
 A dispatch queue for scheduling the delegate calls. The queue doesn't need be a serial queue.

 If `nil` and `delegateOperationQueue` is `nil`, the socket uses main queue for performing all delegate method calls.
 */
@property (nullable, nonatomic, strong) dispatch_queue_t delegateDispatchQueue;

/**
 An operation queue for scheduling the delegate calls.

 If `nil` and `delegateOperationQueue` is `nil`, the socket uses main queue for performing all delegate method calls.
 */
@property (nullable, nonatomic, strong) NSOperationQueue *delegateOperationQueue;

/**
 Current ready state of the socket. Default: `ARTSR_CONNECTING`.

 This property is Key-Value Observable and fully thread-safe.
 */
@property (atomic, assign, readonly) ARTSRReadyState readyState;

/**
 An instance of `NSURL` that this socket connects to.
 */
@property (nullable, nonatomic, strong, readonly) NSURL *url;

/**
 All HTTP headers that were received by socket or `nil` if none were received so far.
 */
@property (nullable, nonatomic, assign, readonly) CFHTTPMessageRef receivedHTTPHeaders;

/**
 Array of `NSHTTPCookie` cookies to apply to the connection.
 */
@property (nullable, nonatomic, copy) NSArray<NSHTTPCookie *> *requestCookies;

/**
 The negotiated web socket protocol or `nil` if handshake did not yet complete.
 */
@property (nullable, nonatomic, copy, readonly) NSString *protocol;

/**
 A boolean value indicating whether this socket will allow connection without SSL trust chain evaluation.
 For DEBUG builds this flag is ignored, and SSL connections are allowed regardless of the certificate trust configuration
 */
@property (nonatomic, assign, readonly) BOOL allowsUntrustedSSLCertificates;

///--------------------------------------
#pragma mark - Constructors
///--------------------------------------

/**
 Initializes a web socket with a given `NSURLRequest`.

 @param request Request to initialize with.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)request logger:(nullable ARTLog *)logger;

/**
 Initializes a web socket with a given `NSURLRequest`, specifying a transport security policy (e.g. SSL configuration).

 @param request        Request to initialize with.
 @param securityPolicy Policy object describing transport security behavior.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)request securityPolicy:(ARTSRSecurityPolicy *)securityPolicy logger:(nullable ARTLog *)logger;

/**
 Initializes a web socket with a given `NSURLRequest` and list of sub-protocols.

 @param request   Request to initialize with.
 @param protocols An array of strings that turn into `Sec-WebSocket-Protocol`. Default: `nil`.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)request protocols:(nullable NSArray<NSString *> *)protocols logger:(nullable ARTLog *)logger;

/**
 Initializes a web socket with a given `NSURLRequest`, list of sub-protocols and whether untrusted SSL certificates are allowed.

 @param request                        Request to initialize with.
 @param protocols                      An array of strings that turn into `Sec-WebSocket-Protocol`. Default: `nil`.
 @param allowsUntrustedSSLCertificates Boolean value indicating whether untrusted SSL certificates are allowed. Default: `false`.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)request protocols:(nullable NSArray<NSString *> *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates logger:(nullable ARTLog *)logger
    DEPRECATED_MSG_ATTRIBUTE("Disabling certificate chain validation is unsafe. "
                             "Please use a proper Certificate Authority to issue your TLS certificates.");

/**
 Initializes a web socket with a given `NSURLRequest`, list of sub-protocols and whether untrusted SSL certificates are allowed.

 @param request        Request to initialize with.
 @param protocols      An array of strings that turn into `Sec-WebSocket-Protocol`. Default: `nil`.
 @param securityPolicy Policy object describing transport security behavior.
 */
- (instancetype)initWithURLRequest:(NSURLRequest *)request protocols:(nullable NSArray<NSString *> *)protocols securityPolicy:(ARTSRSecurityPolicy *)securityPolicy logger:(nullable ARTLog *)logger NS_DESIGNATED_INITIALIZER;

/**
 Initializes a web socket with a given `NSURL`.

 @param url URL to initialize with.
 */
- (instancetype)initWithURL:(NSURL *)url logger:(nullable ARTLog *)logger;

/**
 Initializes a web socket with a given `NSURL` and list of sub-protocols.

 @param url       URL to initialize with.
 @param protocols An array of strings that turn into `Sec-WebSocket-Protocol`. Default: `nil`.
 */
- (instancetype)initWithURL:(NSURL *)url protocols:(nullable NSArray<NSString *> *)protocols logger:(nullable ARTLog *)logger;

/**
 Initializes a web socket with a given `NSURL`, specifying a transport security policy (e.g. SSL configuration).

 @param url            URL to initialize with.
 @param securityPolicy Policy object describing transport security behavior.
 */
- (instancetype)initWithURL:(NSURL *)url securityPolicy:(ARTSRSecurityPolicy *)securityPolicy logger:(nullable ARTLog *)logger;

/**
 Initializes a web socket with a given `NSURL`, list of sub-protocols and whether untrusted SSL certificates are allowed.

 @param url                            URL to initialize with.
 @param protocols                      An array of strings that turn into `Sec-WebSocket-Protocol`. Default: `nil`.
 @param allowsUntrustedSSLCertificates Boolean value indicating whether untrusted SSL certificates are allowed. Default: `false`.
 */
- (instancetype)initWithURL:(NSURL *)url protocols:(nullable NSArray<NSString *> *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates logger:(nullable ARTLog *)logger
    DEPRECATED_MSG_ATTRIBUTE("Disabling certificate chain validation is unsafe. "
                             "Please use a proper Certificate Authority to issue your TLS certificates.");

/**
 Unavailable initializer. Please use any other initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Unavailable constructor. Please use any other initializer.
 */
+ (instancetype)new NS_UNAVAILABLE;

///--------------------------------------
#pragma mark - Schedule
///--------------------------------------

/**
 Schedules a received on a given run loop in a given mode.
 By default, a web socket will schedule itself on `+[NSRunLoop ARTSR_networkRunLoop]` using `NSDefaultRunLoopMode`.

 @param runLoop The run loop on which to schedule the receiver.
 @param mode     The mode for the run loop.
 */
- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode NS_SWIFT_NAME(schedule(in:forMode:));

/**
 Removes the receiver from a given run loop running in a given mode.

 @param runLoop The run loop on which the receiver was scheduled.
 @param mode    The mode for the run loop.
 */
- (void)unscheduleFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode NS_SWIFT_NAME(unschedule(from:forMode:));

///--------------------------------------
#pragma mark - Open / Close
///--------------------------------------

/**
 Opens web socket, which will trigger connection, authentication and start receiving/sending events.
 An instance of `ARTSRWebSocket` is intended for one-time-use only. This method should be called once and only once.
 */
- (void)open;

/**
 Closes a web socket using `ARTSRStatusCodeNormal` code and no reason.
 */
- (void)close;

/**
 Closes a web socket using a given code and reason.

 @param code   Code to close the socket with.
 @param reason Reason to send to the server or `nil`.
 */
- (void)closeWithCode:(NSInteger)code reason:(nullable NSString *)reason;

///--------------------------------------
#pragma mark Send
///--------------------------------------

/**
 Send a UTF-8 string or binary data to the server.

 @param message UTF-8 String or Data to send.
 */
- (void)send:(nullable id)message;

/**
 Send a UTF-8 String to the server.

 @param string String to send.
 @param error  On input, a pointer to variable for an `NSError` object.
 If an error occurs, this pointer is set to an `NSError` object containing information about the error.
 You may specify `nil` to ignore the error information.

 @return `YES` if the string was scheduled to send, otherwise - `NO`.
 */
- (BOOL)sendString:(NSString *)string error:(NSError **)error NS_SWIFT_NAME(send(string:));

/**
 Send binary data to the server.

 @param data  Data to send.
 @param error On input, a pointer to variable for an `NSError` object.
 If an error occurs, this pointer is set to an `NSError` object containing information about the error.
 You may specify `nil` to ignore the error information.

 @return `YES` if the string was scheduled to send, otherwise - `NO`.
 */
- (BOOL)sendData:(nullable NSData *)data error:(NSError **)error NS_SWIFT_NAME(send(data:));

/**
 Send binary data to the server, without making a defensive copy of it first.

 @param data  Data to send.
 @param error On input, a pointer to variable for an `NSError` object.
 If an error occurs, this pointer is set to an `NSError` object containing information about the error.
 You may specify `nil` to ignore the error information.

 @return `YES` if the string was scheduled to send, otherwise - `NO`.
 */
- (BOOL)sendDataNoCopy:(nullable NSData *)data error:(NSError **)error NS_SWIFT_NAME(send(dataNoCopy:));

/**
 Send Ping message to the server with optional data.

 @param data  Instance of `NSData` or `nil`.
 @param error On input, a pointer to variable for an `NSError` object.
 If an error occurs, this pointer is set to an `NSError` object containing information about the error.
 You may specify `nil` to ignore the error information.

 @return `YES` if the string was scheduled to send, otherwise - `NO`.
 */
- (BOOL)sendPing:(nullable NSData *)data error:(NSError **)error NS_SWIFT_NAME(sendPing(_:));

@end

///--------------------------------------
#pragma mark - ARTSRWebSocketDelegate
///--------------------------------------

/**
 The `ARTSRWebSocketDelegate` protocol describes the methods that `ARTSRWebSocket` objects
 call on their delegates to handle status and messsage events.
 */
@protocol ARTSRWebSocketDelegate <NSObject>

@optional

#pragma mark Receive Messages

/**
 Called when any message was received from a web socket.
 This method is suboptimal and might be deprecated in a future release.

 @param webSocket An instance of `ARTSRWebSocket` that received a message.
 @param message   Received message. Either a `String` or `NSData`.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didReceiveMessage:(id)message;

/**
 Called when a frame was received from a web socket.

 @param webSocket An instance of `ARTSRWebSocket` that received a message.
 @param string    Received text in a form of UTF-8 `String`.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didReceiveMessageWithString:(NSString *)string;

/**
 Called when a frame was received from a web socket.

 @param webSocket An instance of `ARTSRWebSocket` that received a message.
 @param data      Received data in a form of `NSData`.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didReceiveMessageWithData:(NSData *)data;

#pragma mark Status & Connection

/**
 Called when a given web socket was open and authenticated.

 @param webSocket An instance of `ARTSRWebSocket` that was open.
 */
- (void)webSocketDidOpen:(ARTSRWebSocket *)webSocket;

/**
 Called when a given web socket encountered an error.

 @param webSocket An instance of `ARTSRWebSocket` that failed with an error.
 @param error     An instance of `NSError`.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didFailWithError:(NSError *)error;

/**
 Called when a given web socket was closed.

 @param webSocket An instance of `ARTSRWebSocket` that was closed.
 @param code      Code reported by the server.
 @param reason    Reason in a form of a String that was reported by the server or `nil`.
 @param wasClean  Boolean value indicating whether a socket was closed in a clean state.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean;

/**
 Called on receive of a ping message from the server.

 @param webSocket An instance of `ARTSRWebSocket` that received a ping frame.
 @param data      Payload that was received or `nil` if there was no payload.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didReceivePingWithData:(nullable NSData *)data;

/**
 Called when a pong data was received in response to ping.

 @param webSocket An instance of `ARTSRWebSocket` that received a pong frame.
 @param pongData  Payload that was received or `nil` if there was no payload.
 */
- (void)webSocket:(ARTSRWebSocket *)webSocket didReceivePong:(nullable NSData *)pongData;

/**
 Sent before reporting a text frame to be able to configure if it shuold be convert to a UTF-8 String or passed as `NSData`.
 If the method is not implemented - it will always convert text frames to String.

 @param webSocket An instance of `ARTSRWebSocket` that received a text frame.

 @return `YES` if text frame should be converted to UTF-8 String, otherwise - `NO`. Default: `YES`.
 */
- (BOOL)webSocketShouldConvertTextFrameToString:(ARTSRWebSocket *)webSocket NS_SWIFT_NAME(webSocketShouldConvertTextFrameToString(_:));

@end

NS_ASSUME_NONNULL_END
