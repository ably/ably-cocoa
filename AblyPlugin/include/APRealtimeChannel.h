@import Foundation;
#import <Ably/ARTTypes.h>

@protocol APLogger;

NS_ASSUME_NONNULL_BEGIN

/// The interface that plugins use to interact with a realtime channel.
///
/// This exists so that plugins do not need to make use of the public `ARTRealtimeChannel` class, which allows the internal components of ably-cocoa to continue the (existing before we introduced plugins) pattern of also not making use of this public class.
///
/// Note that AblyPlugin does not allow you to pass it arbitrary objects that conform to this protocol; rather you must pass it an object which it previously passed to the plugin (e.g. via `prepareChannel:`).
/// TODO mention public API, remove this
NS_SWIFT_NAME(RealtimeChannel)
NS_SWIFT_SENDABLE
@protocol APRealtimeChannel <NSObject>

/// Allows a plugin to store arbitrary key-value data on a channel.
///
/// The channel stores a strong reference to `value`.
- (void)setPluginDataValue:(id)value
                    forKey:(NSString *)key;

/// Allows a plugin to retrieve arbitrary key-value data that was previously stored on the channel using `-setPluginDataValue:forKey:channel:`.
- (nullable id)pluginDataValueForKey:(NSString *)key;

/// Provides plugins with access to ably-cocoa's logging functionality.
@property (nonatomic, readonly) id<APLogger> logger;

/// Throws an error if the channel is in a state in which a message should not be published. Copied from ably-js, not yet implemented. Will document this method properly once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
- (BOOL)throwIfUnpublishableState:(ARTErrorInfo *_Nullable *_Nullable)error;

/// Sends an `OBJECT` `ProtocolMessage` on the channel and indicates the result of waiting for an `ACK`. Copied from ably-js, not yet implemented. Will document this method properly once exact meaning decided, or may replace it with something that makes more sense for ably-cocoa.
- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                          completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error))completion;

@property (nonatomic, readonly) ARTRealtimeChannelState state;

@end

NS_ASSUME_NONNULL_END
