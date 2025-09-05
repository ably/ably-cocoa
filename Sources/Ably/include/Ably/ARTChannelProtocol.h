#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTRest;
@class ARTChannelOptions;
@class ARTMessage;
@class ARTBaseMessage;
@class ARTPaginatedResult<ItemType>;
@class ARTDataQuery;
@class ARTLocalDevice;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which `ARTRestChannelProtocol` and `ARTRealtimeChannelProtocol` are based.
 */
@protocol ARTChannelProtocol

/**
 * The channel name.
 */
@property (readonly) NSString *name;

/**
 * Publishes a single message to the channel with the given event name and payload. When publish is called with this client library, it won't attempt to implicitly attach to the channel, so long as [transient publishing](https://ably.com/docs/realtime/channels#transient-publish) is available in the library. Otherwise, the client will implicitly attach.
 *
 * @param name The name of the message.
 * @param data The payload of the message.
 */
- (void)publish:(nullable NSString *)name data:(nullable id)data;

/**
 * Publishes a single message to the channel with the given event name and payload. A callback may optionally be passed in to this call to be notified of success or failure of the operation. When publish is called with this client library, it won't attempt to implicitly attach to the channel, so long as [transient publishing](https://ably.com/docs/realtime/channels#transient-publish) is available in the library. Otherwise, the client will implicitly attach.
 *
 * @param name The name of the message.
 * @param data The payload of the message.
 * @param callback A success or failure callback function.
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
 * Publishes an array of messages to the channel. A callback may optionally be passed in to this call to be notified of success or failure of the operation.
 *
 * @param messages An array of `ARTMessage` objects.
 * @param callback A success or failure callback function.
 */
- (void)publish:(NSArray<ARTMessage *> *)messages callback:(nullable ARTCallback)callback;

/// :nodoc: TODO: docstring
- (void)history:(ARTPaginatedMessagesCallback)callback;

@end

NS_ASSUME_NONNULL_END
