@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// TODO tidy up what's not needed here
@class ARTErrorInfo;
@class ARTRealtimeChannel;
@class APPublicRealtimeChannelUnderlyingObjects;
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

/// Returns the internal objects that corresponds to a public `ARTRealtimeChannel`.
///
/// Plugins should, in general, not make use of `ARTRealtimeChannel` internally, and instead use `APRealtimeChannel`. This method is intended only to be used in plugin-authored extensions of `ARTRealtimeChannel`.
- (APPublicRealtimeChannelUnderlyingObjects *)underlyingObjectsForPublicRealtimeChannel:(ARTRealtimeChannel *)channel;

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
