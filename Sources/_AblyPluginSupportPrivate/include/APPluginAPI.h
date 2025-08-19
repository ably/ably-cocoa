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
- (void)setPluginDataValue:(id)value
                    forKey:(NSString *)key
                   channel:(id<APRealtimeChannel>)channel;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on a channel using `-setPluginDataValue:forKey:channel:`.
- (nullable id)pluginDataValueForKey:(NSString *)key
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
/// Certain `APPluginAPIProtocol` methods must be called on this queue (the method will document when this is the case).
- (dispatch_queue_t)internalQueueForClient:(id<APRealtimeClient>)client;

/// Sends an `OBJECT` `ProtocolMessage` on a channel and indicates the result of waiting for an `ACK`. TODO there is still some deciding to be done about the exact contract of this method.
///
/// This method must be called on the client's internal queue (see `-internalQueueForClient:`).
- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                             channel:(id<APRealtimeChannel>)channel
                          completion:(void (^ _Nullable)(_Nullable id<APPublicErrorInfo> error))completion;

/// Returns a realtime channel's current state.
- (APRealtimeChannelState)stateForChannel:(id<APRealtimeChannel>)channel;

/// Logs a message to a logger.
- (void)log:(NSString *)message
        withLevel:(APLogLevel)level
        file:(const char *)fileName
        line:(NSInteger)line
        logger:(id<APLogger>)logger;

@end

NS_ASSUME_NONNULL_END
