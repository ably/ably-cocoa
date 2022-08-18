#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTRealtime;
@class ARTEventEmitter;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTConnectionProtocol <NSObject>

/**
 * BEGIN CANONICAL DOCSTRING
 * A unique public identifier for this connection, used to identify this member.
 * END CANONICAL DOCSTRING
 */
@property (nullable, readonly) NSString *id;

/**
 * BEGIN CANONICAL DOCSTRING
 * A unique private connection key used to recover or resume a connection, assigned by Ably. When recovering a connection explicitly, the `recoveryKey` is used in the recover client options as it contains both the key and the last message serial. This private connection key can also be used by other REST clients to publish on behalf of this client. See the [publishing over REST on behalf of a realtime client docs](https://ably.com/docs/rest/channels#publish-on-behalf) for more info.
 * END CANONICAL DOCSTRING
 */
@property (nullable, readonly) NSString *key;

/**
 * BEGIN CANONICAL DOCSTRING
 * The recovery key string can be used by another client to recover this connection's state in the recover client options property. See [connection state recover options](https://ably.com/docs/realtime/connection#connection-state-recover-options) for more information.
 * END CANONICAL DOCSTRING
 */
@property (nullable, readonly) NSString *recoveryKey;

/**
 * BEGIN CANONICAL DOCSTRING
 * The serial number of the last message to be received on this connection, used automatically by the library when recovering or resuming a connection. When recovering a connection explicitly, the `recoveryKey` is used in the recover client options as it contains both the key and the last message serial.
 * END CANONICAL DOCSTRING
 */
@property (readonly) int64_t serial;
@property (readonly) NSInteger maxMessageSize;

/**
 * BEGIN CANONICAL DOCSTRING
 * The current [`ConnectionState`]{@link ConnectionState} of the connection.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimeConnectionState state;

/**
 * BEGIN CANONICAL DOCSTRING
 * An [`ErrorInfo`]{@link ErrorInfo} object describing the last error received if a connection failure occurs.
 * END CANONICAL DOCSTRING
 */
@property (nullable, readonly) ARTErrorInfo *errorReason;

/**
 * BEGIN CANONICAL DOCSTRING
 * Explicitly calling `connect()` is unnecessary unless the `autoConnect` attribute of the [`ClientOptions`]{@link ClientOptions} object is `false`. Unless already connected or connecting, this method causes the connection to open, entering the [`CONNECTING`]{@link ConnectionState#CONNECTING} state.
 * END CANONICAL DOCSTRING
 */
- (void)connect;

/**
 * BEGIN CANONICAL DOCSTRING
 * Causes the connection to close, entering the [`CLOSING`]{@link ConnectionState#CLOSING} state. Once closed, the library does not attempt to re-establish the connection without an explicit call to [`connect()`]{@link Connection#connect}.
 * END CANONICAL DOCSTRING
 */
- (void)close;
- (void)ping:(ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Embeds an [`EventEmitter`]{@link EventEmitter} object.
 * END CANONICAL DOCSTRING
 */
ART_EMBED_INTERFACE_EVENT_EMITTER(ARTRealtimeConnectionEvent, ARTConnectionStateChange *)

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables the management of a connection to Ably.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTConnection represents the connection associated with an ``ARTRealtime`` instance. It exposes the lifecycle and parameters of the realtime connection.
 * END LEGACY DOCSTRING
 */
@interface ARTConnection: NSObject <ARTConnectionProtocol>

@end

#pragma mark - ARTEvent

@interface ARTEvent (ConnectionEvent)
- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
@end

NS_ASSUME_NONNULL_END
