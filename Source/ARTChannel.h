#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTDataEncoder.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTChannelOptions;
@class ARTMessage;
@class ARTBaseMessage;
@class ARTPaginatedResult<ItemType>;
@class ARTDataQuery;
@class ARTLocalDevice;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTChannel` is implemented.
 */
@protocol ARTChannelProtocol

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The channel name.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) NSString *name;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Publishes a single message to the channel with the given event name and payload. When publish is called with this client library, it won't attempt to implicitly attach to the channel, so long as [transient publishing](https://ably.com/docs/realtime/channels#transient-publish) is available in the library. Otherwise, the client will implicitly attach.
 *
 * @param name The name of the message.
 * @param data The payload of the message.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)publish:(nullable NSString *)name data:(nullable id)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Publishes a single message to the channel with the given event name and payload. A callback may optionally be passed in to this call to be notified of success or failure of the operation. When publish is called with this client library, it won't attempt to implicitly attach to the channel, so long as [transient publishing](https://ably.com/docs/realtime/channels#transient-publish) is available in the library. Otherwise, the client will implicitly attach.
 *
 * @param name The name of the message.
 * @param data The payload of the message.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)publish:(nullable NSString *)name data:(nullable id)data callback:(nullable ARTCallback)callback;

/// :nodoc: TODO: docstring
- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId;

/// :nodoc: TODO: docstring
- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId callback:(nullable ARTCallback)callback;

/// :nodoc: TODO: docstring
- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras;

/// :nodoc: TODO: docstring
- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback;

/// :nodoc: TODO: docstring
- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras;

/// :nodoc: TODO: docstring
- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback;

/// :nodoc: TODO: docstring
- (void)publish:(NSArray<ARTMessage *> *)messages;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Publishes an array of messages to the channel. A callback may optionally be passed in to this call to be notified of success or failure of the operation.
 *
 * @param messages An array of `ARTMessage` objects.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)publish:(NSArray<ARTMessage *> *)messages callback:(nullable ARTCallback)callback;

/// :nodoc: TODO: docstring
- (void)history:(ARTPaginatedMessagesCallback)callback;

@end

/**
 * The base class for `ARTRestChannel` and `ARTRealtimeChannel`.
 * Ably platform service organizes the message traffic within applications into named channels. Channels are the medium through which messages are distributed; clients attach to channels to subscribe to messages, and every message published to a unique channel is broadcast by Ably to all subscribers.
 *
 * @see See `ARTChannelProtocol` for details.
 */
@interface ARTChannel : NSObject<ARTChannelProtocol>

/// :nodoc:
@property (nonatomic, strong, readonly) NSString *name;

@end

NS_ASSUME_NONNULL_END
