@import Foundation;
@import Ably;

NS_ASSUME_NONNULL_BEGIN

@protocol APLogger;
@protocol APObjectMessageProtocol;
@protocol APRealtimeChannel;
@protocol APRealtimeClient;

/// `APPluginAPIProtocol` provides a stable API (that is, one which will not introduce backwards-incompatible changes within a given major version of ably-cocoa) for Ably-authored plugins to access certain private functionality of ably-cocoa.
///
/// The canonical implementation of this protocol is that returned by `+[APPluginAPI sharedInstance]`.
NS_SWIFT_NAME(PluginAPIProtocol)
NS_SWIFT_SENDABLE
@protocol APPluginAPIProtocol

/// Returns the internal `APRealtimeChannel` that corresponds to a public `ARTRealtimeChannel`.
///
/// Plugins should, in general, not make use of `ARTRealtimeChannel` internally, and instead use `APRealtimeChannel`. This method is intended only to be used in plugin-authored extensions of `ARTRealtimeChannel`.
- (id<APRealtimeChannel>)channelForPublicRealtimeChannel:(ARTRealtimeChannel *)channel;

/// Allows a plugin to store arbitrary key-value data on a channel.
///
/// The channel stores a strong reference to `value`.
- (void)setPluginDataValue:(id)value
                    forKey:(NSString *)key
                   channel:(id<APRealtimeChannel>)channel;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on a channel using `-setPluginDataValue:forKey:channel:`.
- (nullable id)pluginDataValueForKey:(NSString *)key
                             channel:(id<APRealtimeChannel>)channel;

/// Provides plugins with access to ably-cocoa's logging functionality.
///
/// - Parameter channel: The channel whose logger the returned logger should wrap.
- (id<APLogger>)loggerForChannel:(id<APRealtimeChannel>)channel;

/// Throws an error if the channel is in a state in which a message should not be published. Copied from ably-js, not yet implemented. Will document this method properly once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
- (BOOL)throwIfUnpublishableStateForChannel:(id<APRealtimeChannel>)channel
                                      error:(ARTErrorInfo *_Nullable *_Nullable)error;

/// Sends an `OBJECT` `ProtocolMessage` on a channel and indicates the result of waiting for an `ACK`. Copied from ably-js, not yet implemented. Will document this method properly once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                             channel:(id<APRealtimeChannel>)channel
                          completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error))completion;

/// Returns the server time, as calculated from the `ARTRealtimeInstance`'s stored offset between the local clock and the server time. Copied from ably-js, not yet implemented. Will document this method once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
- (void)fetchTimestampWithQueryTime:(BOOL)queryTime
                           realtime:(id<APRealtimeClient>)realtime
                         completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error, NSDate *_Nullable timestamp))completion;

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
