@import Foundation;
#import "APRealtimeChannelState.h"

NS_ASSUME_NONNULL_BEGIN

/// A copy of the object-related subset of ably-cocoa's `ARTChannelMode`. The raw values match
/// `ARTChannelMode` (`ARTChannelModeObjectSubscribe`/`ARTChannelModeObjectPublish`) so the two can be
/// bridged bit-for-bit. Used by the RTO2a2/RTO2b2 channel-mode guards of the LiveObjects plugin.
typedef NS_OPTIONS(NSUInteger, APChannelMode) {
    APChannelModeObjectSubscribe = 1 << 24,
    APChannelModeObjectPublish = 1 << 25,
} NS_SWIFT_NAME(ChannelMode);

@protocol APLogger;
@protocol APObjectMessageProtocol;
@protocol APRealtimeChannel;
@protocol APRealtimeClient;
@protocol APPublicRealtimeChannelUnderlyingObjects;
@protocol APPublicClientOptions;
@protocol APPublicRealtimeChannel;
@protocol APPublicErrorInfo;
@protocol APPublishResultProtocol;

/// `APPluginAPIProtocol` provides a stable API for Ably-authored plugins to access certain private functionality of ably-cocoa.
NS_SWIFT_NAME(PluginAPIProtocol)
NS_SWIFT_SENDABLE
@protocol APPluginAPIProtocol

/// Whether the SDK uses a protocol version which, as far as a LiveObjects
/// plugin is concerned, is equivalent to protocol v6.
///
/// If the SDK uses a protocol version which is higher than 6 but whose
/// breaking changes compared to v6 do not affect LiveObjects plugins, this
/// property may still return `YES`.
///
/// This property **must** return `YES`. If you wish to introduce a protocol
/// version change, see the "Breaking Realtime protocol version changes"
/// section in the Readme.
@property (nonatomic, readonly) BOOL usesLiveObjectsProtocolV6;

/// Returns the internal objects that correspond to a public `ARTRealtimeChannel`.
///
/// Plugins should, in general, not make use of `ARTRealtimeChannel` internally, and instead use `APRealtimeChannel`. This method is intended only to be used in plugin-authored extensions of `ARTRealtimeChannel`.
- (id<APPublicRealtimeChannelUnderlyingObjects>)underlyingObjectsForPublicRealtimeChannel:(id<APPublicRealtimeChannel>)channel;

/// Allows a plugin to store arbitrary key-value data on a channel.
///
/// The channel stores a strong reference to `value`.
- (void)nosync_setPluginDataValue:(id)value
                           forKey:(NSString *)key
                          channel:(id<APRealtimeChannel>)channel;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on a channel using `-setPluginDataValue:forKey:channel:`.
- (nullable id)nosync_pluginDataValueForKey:(NSString *)key
                                    channel:(id<APRealtimeChannel>)channel;

/// Allows a plugin to store arbitrary key-value data in an `ARTClientOptions`. This allows a plugin to define its own client options.
///
/// You would usually call this from within a plugin-defined extension of `ARTClientOptions`.
- (void)setPluginOptionsValue:(id)value
                       forKey:(NSString *)key
                clientOptions:(id<APPublicClientOptions>)options;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on an `ARTClientOptions` using `-setPluginOptionsValue:forKey:clientOptions:`.
///
/// You would usually call this from within a plugin-defined extension of `ARTClientOptions`.
- (nullable id)pluginOptionsValueForKey:(NSString *)key
                          clientOptions:(id<APPublicClientOptions>)options;

/// Retrieves a copy of the options for a client.
- (id<APPublicClientOptions>)optionsForClient:(id<APRealtimeClient>)client;

/// Provides plugins with access to ably-cocoa's logging functionality.
///
/// - Parameter channel: The channel whose logger the returned logger should wrap.
- (id<APLogger>)loggerForChannel:(id<APRealtimeChannel>)channel;

/// The name of a realtime channel.
///
/// Used by the LiveObjects plugin to populate the `channel` field of a public `ObjectMessage`
/// (PAOM2e/PAOM3b).
- (NSString *)nameForChannel:(id<APRealtimeChannel>)channel;

/// Provides plugins with the queue on which all user callbacks for a given client should be called.
- (dispatch_queue_t)callbackQueueForClient:(id<APRealtimeClient>)client;

/// Provides plugins with the queue which a given client uses to synchronize its internal state.
///
/// All `_AblyPluginSupportPrivate` methods whose names begin with `nosync_` must be called on this queue.
- (dispatch_queue_t)internalQueueForClient:(id<APRealtimeClient>)client;

/// Attempts to submit an `OBJECT` `ProtocolMessage` for best-effort delivery to Ably per RTO15.
///
/// This enables the channel message publishing behaviour described in RTL6c:
///
/// - If the channel's state is neither SUSPENDED nor FAILED then the message will be submitted to the connection for further checks per RTL6c1 and RTL6c2. Note that these checks may cause the connection to immediately reject the message per RTL6c4.
/// - If the channel's state is SUSPENDED or FAILED then the callback will be called immediately with an error per RTL6c4.
///
/// If the message ends up being sent on the transport then the completion handler will be called to indicate the result of waiting for an `ACK` or `NACK`, or when the connection gives up on trying to send the message. The completion handler receives an `APPublishResultProtocol` containing the serials assigned to the published messages by the server.
///
/// The completion handler will be called on the client's internal queue (see `-internalQueueForClient:`).
///
/// This method will call ``APLiveObjectsPlugin/encodeObjectMessage:format:`` to encode the `ObjectMessage`s to be sent over the wire, per RTO15c.
///
/// - Note: This method does not currently implement the RTO15d message size checks; this will come in https://github.com/ably/ably-liveobjects-swift-plugin/issues/13.
- (void)nosync_sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                                    channel:(id<APRealtimeChannel>)channel
                                 completion:(void (^ _Nullable)(_Nullable id<APPublishResultProtocol> publishResult, _Nullable id<APPublicErrorInfo> error))completion;

/// Returns a realtime channel's current state.
- (APRealtimeChannelState)nosync_stateForChannel:(id<APRealtimeChannel>)channel;

/// The channel's effective object-related channel modes, resolved per RTO2a/RTO2b: the attached modes
/// if present (RTO2a), otherwise the user-provided channel-options modes (RTO2b). Only the
/// `ObjectSubscribe`/`ObjectPublish` bits are reported. Used by the RTO2a2/RTO2b2 channel-mode guards.
- (APChannelMode)nosync_objectChannelModesForChannel:(id<APRealtimeChannel>)channel;

/// The error that makes the client's connection unpublishable, or `nil` if the connection is in a
/// state from which messages can be published. When not active, returns the connection's current error
/// reason if it has one. Spec: RTO15b (the publish adheres to the RTL6c connection-state conditions).
- (nullable id<APPublicErrorInfo>)nosync_connectionStateErrorForClient:(id<APRealtimeClient>)client;

/// Initiates an attach on a realtime channel, per the RTL33b implicit-attach used by a plugin's
/// *ensure-active-channel* procedure (RTL33 / RTO23e). This is a thin bridge onto the channel's
/// existing attach (equivalent to the public `-[ARTRealtimeChannel attach:]`): if the channel is
/// already attached (or an attach/detach is in flight) it resolves per RTL4h without starting a
/// redundant attach.
///
/// The completion handler is called with a `nil` error on success, or the `ErrorInfo` that caused
/// the attach to fail (RTL33b1).
///
/// The completion handler will be called on the client's internal queue (see
/// `-internalQueueForClient:`).
- (void)nosync_attachChannel:(id<APRealtimeChannel>)channel
                  completion:(void (^ _Nullable)(_Nullable id<APPublicErrorInfo> error))completion;

/// Fetches the Ably server time from the REST API, per RTO16.
///
/// Per RTO16a, if the client knows the local clock's offset from the server time, then the server time will be calculated without making a request.
///
/// The completion handler will be called on the client's internal queue (see `-internalQueueForClient:`).
- (void)nosync_fetchServerTimeForClient:(id<APRealtimeClient>)client
                             completion:(void (^ _Nullable)(NSDate *_Nullable serverTime, _Nullable id<APPublicErrorInfo> error))completion;

/// The `connectionDetails` from the latest `CONNECTED` `ProtocolMessage` that the client received (`nil` if it did not contain a `connectionDetails`).
- (nullable id<APConnectionDetailsProtocol>)nosync_latestConnectionDetailsForClient:(id<APRealtimeClient>)client;

/// Logs a message to a logger.
- (void)log:(NSString *)message
        withLevel:(APLogLevel)level
        file:(const char *)fileName
        line:(NSInteger)line
        logger:(id<APLogger>)logger;

@end

NS_ASSUME_NONNULL_END
