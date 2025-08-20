#import <Foundation/Foundation.h>
#import "APEncodingFormat.h"

@class ARTRealtimeChannel;
@class ARTErrorInfo;
@protocol APLiveObjectsInternalPluginProtocol;
@protocol APObjectMessageProtocol;
@protocol APDecodingContextProtocol;
@protocol APRealtimeChannel;
@protocol APRealtimeClient;

NS_ASSUME_NONNULL_BEGIN

/// The entrypoint by which ably-cocoa accesses the functionality provided by the LiveObjects plugin.
///
/// The value that the user provides for the `ARTPluginNameLiveObjects` key in the  `-[ARTClientOptions plugins]` client option must _informally_ conform to this protocol; that is, it must implement its methods but not declare itself as conforming to the protocol. (We use informal conformance so that the LiveObjects plugin does not need to expose its usage of the `ARTPlugin` library to the user.)
NS_SWIFT_NAME(LiveObjectsPluginProtocol)
NS_SWIFT_SENDABLE
@protocol APLiveObjectsPluginProtocol <NSObject>

/// Provides ably-cocoa with an implementation of `APLiveObjectsInternalPluginProtocol`.
+ (id<APLiveObjectsInternalPluginProtocol>)internalPlugin;

@end

/// The interface that ably-cocoa uses to access the functionality provided by the LiveObjects plugin.
///
/// This protocol can be more complex than `APLiveObjectsPluginProtocol`, because, since its implementation will be internal to the LiveObjects plugin library, then, unlike the informal conformance that we have to use for `APLiveObjectsPluginProtocol`, the implementation can declare itself as conforming to this protocol and will receive compiler checking that it does indeed conform.
NS_SWIFT_NAME(LiveObjectsInternalPluginProtocol)
NS_SWIFT_SENDABLE
@protocol APLiveObjectsInternalPluginProtocol <NSObject>

/// ably-cocoa will call this method when initializing an `ARTRealtimeChannel` instance.
///
/// The plugin can use this as an opportunity to perform any initial setup of LiveObjects functionality for this channel.
- (void)prepareChannel:(id<APRealtimeChannel>)channel client:(id<APRealtimeClient>)client;

/// Decodes an `ObjectMessage` received over the wire.
///
/// Parameters:
/// - serialized: A dictionary that contains the representation of the `ObjectMessage` received over the wire. To find out what kinds of values you should expect to find here for a given `format`, see th decoding rules described in `APEncodingFormat`.
/// - context: Contains information that may be needed in the decoding, such as information about the containing `ProtocolMessage`.
/// - format: The format that was used to create `serialized`, and whose rules should be used when decoding the `ObjectMessage`.
///
/// Returns: A `ObjectMessageProtocol` object that ably-cocoa can later pass to this plugin's `-handleObjectProtocolMessageWithObjectMessages:channel:` method, or `nil` if decoding fails (in which case `error` must be populated).
- (nullable id<APObjectMessageProtocol>)decodeObjectMessage:(NSDictionary<NSString *, id> *)serialized
                                                    context:(id<APDecodingContextProtocol>)context
                                                     format:(APEncodingFormat)format
                                                      error:(ARTErrorInfo *_Nullable *_Nullable)error;

/// Encodes an `ObjectMessage` to be sent over the wire.
///
/// Parameters:
/// - objectMessage: An `ObjectMessage` that this plugin earlier passed to `APPluginAPI`'s `-sendObjectWithObjectMessages:channel:completion:`.
/// - format: The format whose rules should be used when encoding the `ObjectMessage`.
///
/// Returns: See the encoding rules described in `APEncodingFormat`.
- (NSDictionary<NSString *, id> *)encodeObjectMessage:(id<APObjectMessageProtocol>)objectMessage
                                               format:(APEncodingFormat)format;

/// Called when a channel received an `ATTACHED` `ProtocolMessage`. (This is copied from ably-js, will document this method properly once exact meaning decided.)
///
/// TODO: what thread is this called on, and does it matter? Decide in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3
///
/// Parameters:
/// - channel: The channel that received the `ProtocolMessage`.
/// - hasObjects: Whether the `ProtocolMessage` has the `HAS_OBJECTS` flag set.
- (void)onChannelAttached:(id<APRealtimeChannel>)channel
               hasObjects:(BOOL)hasObjects;

/// Processes a received `OBJECT` `ProtocolMessage`.
///
/// TODO: what thread is this called on, and does it matter? Decide in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3
///
/// Parameters:
/// - objectMessages: The contents of the `ProtocolMessage`'s `state` property.
/// - channel: The channel on which the `ProtocolMessage` was received.
- (void)handleObjectProtocolMessageWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                                              channel:(id<APRealtimeChannel>)channel;

/// Processes a received `OBJECT_SYNC` `ProtocolMessage`.
///
/// TODO: what thread is this called on, and does it matter? Decide in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3
///
/// Parameters:
/// - objectMessages: The contents of the `ProtocolMessage`'s `state` property.
/// - channel: The channel on which the `ProtocolMessage` was received.
- (void)handleObjectSyncProtocolMessageWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                             protocolMessageChannelSerial:(nullable NSString *)protocolMessageChannelSerial
                                                  channel:(id<APRealtimeChannel>)channel;

@end

/// An `ObjectMessage`, as found in the `state` property of an `OBJECT` or `OBJECT_SYNC` `ProtocolMessage`.
///
/// This protocol is empty because ably-cocoa does not need to interact with the contents of an `ObjectMessage`.
///
/// An instance of `APLiveObjectsInternalPluginProtocol` is expected to be able to handle any `APObjectMessageProtocol` instance that it creates.
NS_SWIFT_NAME(ObjectMessageProtocol)
NS_SWIFT_SENDABLE
@protocol APObjectMessageProtocol
@end

NS_ASSUME_NONNULL_END
