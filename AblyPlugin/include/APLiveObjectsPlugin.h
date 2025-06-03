#import <Foundation/Foundation.h>

@class ARTRealtimeChannel;
@protocol APLiveObjectsInternalPluginProtocol;
@protocol APObjectMessageProtocol;

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
- (void)prepareChannel:(ARTRealtimeChannel *)channel;

/// Decodes an `ObjectMessage` received over the wire. Copied from ably-js; the exact meaning of this method and what it should return still to be decided. There will almost certainly be further parameters to add relating to format etc.
- (id<APObjectMessageProtocol>)decodeObjectMessage:(NSDictionary *)serialized;

/// Encodes an `ObjectMessage` to be sent over the wire. Copied from ably-js; the exact meaning of this method and what it should return still to be decided
- (NSDictionary *)encodeObjectMessage:(id<APObjectMessageProtocol>)objectMessage;

/// Called when a channel received an `ATTACHED` `ProtocolMessage`. (This is copied from ably-js, will document this method properly once exact meaning decided.)
///
/// TODO: what thread is this called on, and does it matter? Decide in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3
///
/// Parameters:
/// - channel: The channel that received the `ProtocolMessage`.
/// - hasObjects: Whether the `ProtocolMessage` has the `HAS_OBJECTS` flag set.
- (void)onChannelAttached:(ARTRealtimeChannel *)channel
               hasObjects:(BOOL)hasObjects;

/// Processes a received `OBJECT` `ProtocolMessage`.
///
/// TODO: what thread is this called on, and does it matter? Decide in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3
///
/// Parameters:
/// - objectMessages: The contents of the `ProtocolMessage`'s `state` property.
/// - channel: The channel on which the `ProtocolMessage` was received.
- (void)handleObjectProtocolMessageWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                                              channel:(ARTRealtimeChannel *)channel;

/// Processes a received `OBJECT_SYNC` `ProtocolMessage`.
///
/// TODO: what thread is this called on, and does it matter? Decide in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3
///
/// Parameters:
/// - objectMessages: The contents of the `ProtocolMessage`'s `state` property.
/// - channel: The channel on which the `ProtocolMessage` was received.
- (void)handleObjectSyncProtocolMessageWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                             protocolMessageChannelSerial:(NSString *)protocolMessageChannelSerial
                                                  channel:(ARTRealtimeChannel *)channel;

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
