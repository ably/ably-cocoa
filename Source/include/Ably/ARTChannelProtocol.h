#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import "ARTStringifiable.h"

@class ARTRest;
@class ARTChannelOptions;
@class ARTMessage;
@class ARTMessageOperation;
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

/**
 * Publishes an update to an existing message with patch semantics. Non-null `name`, `data`, and `extras` fields in the provided message will replace the corresponding fields in the existing message, while null fields will be left unchanged.
 *
 * @param message An `ARTMessage` object containing a populated `serial` field and the fields to update.
 * @param operation An optional `ARTMessageOperation` object containing metadata about the update operation.
 * @param params Optional parameters sent as part of the query string.
 * @param callback A callback which, upon success, will contain a `ARTMessage` object containing the updated message. Upon failure, the callback will contain an `ARTErrorInfo` object which explains the error.
 */
- (void)updateMessage:(ARTMessage *)message
            operation:(nullable ARTMessageOperation *)operation
               params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
             callback:(nullable ARTCallback)callback;

/**
 * Marks a message as deleted by publishing an update with an action of `ARTMessageActionDelete`. This does not remove the message from the server, and the full message history remains accessible. Uses patch semantics: non-null `name`, `data`, and `extras` fields in the provided message will replace the corresponding fields in the existing message, while null fields will be left unchanged (meaning that if you for example want the `ARTMessageActionDelete` to have an empty data, you should explicitly set the `data` to an empty object).
 *
 * @param message An `ARTMessage` object containing a populated `serial` field.
 * @param operation An optional `ARTMessageOperation` object containing metadata about the delete operation.
 * @param params Optional parameters sent as part of the query string.
 * @param callback A callback which, upon success, will contain a `ARTMessage` object containing the deleted message. Upon failure, the callback will contain an `ARTErrorInfo` object which explains the error.
 */
- (void)deleteMessage:(ARTMessage *)message
            operation:(nullable ARTMessageOperation *)operation
               params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
             callback:(nullable ARTCallback)callback;

/**
 * Retrieves the latest version of a specific message by its serial identifier.
 *
 * @param serial A serial identifier string of the message to retrieve.
 * @param callback A callback which, upon success, will contain a `ARTMessage` object representing the latest version of the message. Upon failure, the callback will contain an `ARTErrorInfo` object which explains the error.
 */
- (void)getMessageWithSerial:(NSString *)serial callback:(ARTMessageErrorCallback)callback;

/**
 * Retrieves all historical versions of a specific message, ordered by version. This includes the original message and all subsequent updates or delete operations.
 *
 * @param serial A serial identifier string of the message whose versions are to be retrieved.
 * @param params Optional parameters sent as part of the query string.
 * @param callback A callback which, upon success, will contain an `ARTPaginatedResult` object containing an array of `ARTMessage` objects representing all versions of the message. Upon failure, the callback will contain an `ARTErrorInfo` object which explains the error.
 */
- (void)getMessageVersionsWithSerial:(NSString *)serial
                              params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
                            callback:(ARTPaginatedMessagesCallback)callback;

/**
 * Retrieves all historical versions of a specific message, ordered by version. This includes the original message and all subsequent updates or delete operations.
 *
 * @param serial A serial identifier string of the message whose versions are to be retrieved.
 * @param callback A callback which, upon success, will contain an `ARTPaginatedResult` object containing an array of `ARTMessage` objects representing all versions of the message. Upon failure, the callback will contain an `ARTErrorInfo` object which explains the error.
 */
- (void)getMessageVersionsWithSerial:(NSString *)serial callback:(ARTPaginatedMessagesCallback)callback;

/// :nodoc: TODO: docstring
- (void)history:(ARTPaginatedMessagesCallback)callback;

@end

NS_ASSUME_NONNULL_END
