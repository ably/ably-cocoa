@import Foundation;
@import Ably;

NS_ASSUME_NONNULL_BEGIN

@protocol APLogger;
@protocol APObjectMessageProtocol;
@protocol APRealtimeChannel;
@protocol APRealtimeClient;
@protocol APPublicRealtimeChannelUnderlyingObjects;

/// `APPluginAPIProtocol` provides a stable API (that is, one which will not introduce backwards-incompatible changes within a given major version of ably-cocoa) for Ably-authored plugins to access certain private functionality of ably-cocoa.
///
/// The canonical implementation of this protocol is that returned by `+[APPluginAPI sharedInstance]`.
NS_SWIFT_NAME(PluginAPIProtocol)
NS_SWIFT_SENDABLE
@protocol APPluginAPIProtocol

/// Returns the internal objects that correspond to a public `ARTRealtimeChannel`.
///
/// Plugins should, in general, not make use of `ARTRealtimeChannel` internally, and instead use `APRealtimeChannel`. This method is intended only to be used in plugin-authored extensions of `ARTRealtimeChannel`.
- (id<APPublicRealtimeChannelUnderlyingObjects>)underlyingObjectsForPublicRealtimeChannel:(ARTRealtimeChannel *)channel;

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
                clientOptions:(ARTClientOptions *)options;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on an `ARTClientOptions` using `-setPluginOptionsValue:forKey:clientOptions:`.
///
/// You would usually call this from within a plugin-defined extension of `ARTClientOptions`.
- (nullable id)pluginOptionsValueForKey:(NSString *)key
                          clientOptions:(ARTClientOptions *)options;

/// Retrieves a copy of the options for a client.
- (ARTClientOptions *)optionsForClient:(id<APRealtimeClient>)client;

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

/// Sends an `OBJECT` `ProtocolMessage` on a channel and indicates the result of waiting for an `ACK`. Copied from ably-js, not yet implemented. Will document this method properly once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
///
/// This method must be called on the client's internal queue (see `-internalQueueForClient:`).
- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                             channel:(id<APRealtimeChannel>)channel
                          completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error))completion;

@end

/// Provides the canonical implementation of `APPluginAPIProtocol`. This is the class that Ably-authored plugins should use to access private functionality of ably-cocoa.
NS_SWIFT_NAME(PluginAPI)
NS_SWIFT_SENDABLE
@interface APPluginAPI: NSObject <APPluginAPIProtocol>

/// Returns the singleton instance of this class.
+ (APPluginAPI *)sharedInstance;

// Use `+sharedInstance` instead.
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
