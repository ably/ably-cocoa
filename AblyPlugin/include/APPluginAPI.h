@import Foundation;
@import Ably;

NS_ASSUME_NONNULL_BEGIN

@protocol APLogger;

/// `APPluginAPIProtocol` provides a stable API (that is, one which will not introduce backwards-incompatible changes within a given major version of ably-cocoa) for Ably-authored plugins to access certain private functionality of ably-cocoa.
///
/// The canonical implementation of this protocol is that returned by `+[APPluginAPI sharedInstance]`.
NS_SWIFT_NAME(PluginAPIProtocol)
NS_SWIFT_SENDABLE
@protocol APPluginAPIProtocol

/// Allows a plugin to store arbitrary key-value data on a channel.
///
/// The channel stores a strong reference to `value`.
- (void)setPluginDataValue:(id)value
                    forKey:(NSString *)key
                   channel:(ARTRealtimeChannel *)channel;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on a channel using `-setPluginDataValue:forKey:channel:`.
- (nullable id)pluginDataValueForKey:(NSString *)key
                             channel:(ARTRealtimeChannel *)channel;

/// Provides plugins with access to ably-cocoa's logging functionality.
///
/// - Parameter channel: The channel whose logger the returned logger should wrap.
- (id<APLogger>)loggerForChannel:(ARTRealtimeChannel *)channel;

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
