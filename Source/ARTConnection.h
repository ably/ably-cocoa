#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTRealtime;
@class ARTEventEmitter;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTConnection` is implemented.
 */
@protocol ARTConnectionProtocol <NSObject>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A unique public identifier for this connection, used to identify this member.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, readonly) NSString *id;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A unique private connection key used to recover or resume a connection, assigned by Ably. When recovering a connection explicitly, the `recoveryKey` is used in the recover client options as it contains both the key and the last message serial. This private connection key can also be used by other REST clients to publish on behalf of this client. See the [publishing over REST on behalf of a realtime client docs](https://ably.com/docs/rest/channels#publish-on-behalf) for more info.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, readonly) NSString *key;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The recovery key string can be used by another client to recover this connection's state in the recover client options property. See [connection state recover options](https://ably.com/docs/realtime/connection#connection-state-recover-options) for more information.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, readonly) NSString *recoveryKey;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The serial number of the last message to be received on this connection, used automatically by the library when recovering or resuming a connection. When recovering a connection explicitly, the `recoveryKey` is used in the recover client options as it contains both the key and the last message serial.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) int64_t serial;

/**
 * The maximum message size is an attribute of an Ably account and enforced by Ably servers. `maxMessageSize` indicates the maximum message size allowed by the Ably account this connection is using. Overrides the default value of `-[ARTDefault maxMessageSize]`.
 */
@property (readonly) NSInteger maxMessageSize;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The current `ARTRealtimeConnectionState` of the connection.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTRealtimeConnectionState state;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTErrorInfo` object describing the last error received if a connection failure occurs.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, readonly) ARTErrorInfo *errorReason;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Explicitly calling `connect` is unnecessary unless the `ARTClientOptions.autoConnect` is `false`. Unless already connected or connecting, this method causes the connection to open, entering the `ARTRealtimeConnecting` state.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)connect;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Causes the connection to close, entering the `ARTRealtimeClosing` state. Once closed, the library does not attempt to re-establish the connection without an explicit call to `-[ARTConnectionProtocol connect]`.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)close;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When connected, sends a heartbeat ping to the Ably server and executes the callback with an error if any. This can be useful for measuring true round-trip latency to the connected Ably server.
 *
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)ping:(ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Embeds an `ARTEventEmitter` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
ART_EMBED_INTERFACE_EVENT_EMITTER(ARTRealtimeConnectionEvent, ARTConnectionStateChange *)

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables the management of a connection to Ably.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * ARTConnection represents the connection associated with an `ARTRealtime` instance. It exposes the lifecycle and parameters of the realtime connection.
 * END LEGACY DOCSTRING
 */
@interface ARTConnection: NSObject <ARTConnectionProtocol>

@end

#pragma mark - ARTEvent

/// :nodoc:
@interface ARTEvent (ConnectionEvent)
- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
@end

NS_ASSUME_NONNULL_END
