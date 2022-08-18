#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTRealtime;
@class ARTEventEmitter;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTConnectionProtocol <NSObject>

@property (nullable, readonly) NSString *id;
@property (nullable, readonly) NSString *key;
@property (nullable, readonly) NSString *recoveryKey;
@property (readonly) int64_t serial;
@property (readonly) NSInteger maxMessageSize;
@property (readonly) ARTRealtimeConnectionState state;

/**
 * BEGIN CANONICAL DOCSTRING
 * An [`ErrorInfo`]{@link ErrorInfo} object describing the last error received if a connection failure occurs.
 * END CANONICAL DOCSTRING
 */
@property (nullable, readonly) ARTErrorInfo *errorReason;

- (void)connect;
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
