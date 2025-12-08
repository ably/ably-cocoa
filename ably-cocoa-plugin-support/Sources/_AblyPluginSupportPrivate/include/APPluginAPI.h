@import Foundation;
#import "APRealtimeChannelState.h"

NS_ASSUME_NONNULL_BEGIN

@protocol APLogger;
@protocol APObjectMessageProtocol;
@protocol APRealtimeChannel;
@protocol APRealtimeClient;
@protocol APPublicRealtimeChannelUnderlyingObjects;
@protocol APPublicClientOptions;
@protocol APPublicRealtimeChannel;
@protocol APPublicErrorInfo;

/// `APPluginAPIProtocol` provides a stable API for Ably-authored plugins to access certain private functionality of ably-cocoa.
NS_SWIFT_NAME(PluginAPIProtocol)
NS_SWIFT_SENDABLE
@protocol APPluginAPIProtocol

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
/// If the message ends up being sent on the transport then the completion handler will be called to indicate the result of waiting for an `ACK` or `NACK`, or when the connection gives up on trying to send the message.
///
/// The completion handler will be called on the client's internal queue (see `-internalQueueForClient:`).
///
/// This method will call ``APLiveObjectsPlugin/encodeObjectMessage:format:`` to encode the `ObjectMessage`s to be sent over the wire, per RTO15c.
///
/// - Note: This method does not currently implement the RTO15d message size checks; this will come in https://github.com/ably/ably-liveobjects-swift-plugin/issues/13.
- (void)nosync_sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                                    channel:(id<APRealtimeChannel>)channel
                                 completion:(void (^ _Nullable)(_Nullable id<APPublicErrorInfo> error))completion;

/// Returns a realtime channel's current state.
- (APRealtimeChannelState)nosync_stateForChannel:(id<APRealtimeChannel>)channel;

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
