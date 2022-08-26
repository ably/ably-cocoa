#import <Foundation/Foundation.h>

#import <Ably/ARTRestPresence.h>
#import <Ably/ARTDataQuery.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceQuery : ARTPresenceQuery

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Sets whether to wait for a full presence set synchronization between Ably and the clients on the channel to complete before returning the results. Synchronization begins as soon as the channel is `ARTRealtimeChannelAttached`. When set to `true` the results will be returned as soon as the sync is complete. When set to `false` the current list of members will be returned without the sync completing. The default is `true`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, nonatomic) BOOL waitForSync;

@end

/**
 The protocol upon which the `ARTRealtimePresence` is implemented.
 */
@protocol ARTRealtimePresenceProtocol

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Indicates whether the presence set synchronization between Ably and the clients on the channel has been completed. Set to `true` when the sync is complete.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) BOOL syncComplete;

- (void)get:(ARTPresenceMessagesCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTRealtimePresenceQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)get:(ARTRealtimePresenceQuery *)query callback:(ARTPresenceMessagesCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enters the presence set for the channel, optionally passing a `data` payload. A `clientId` is required to be present on a channel.
 *
 * @param data The payload associated with the presence member.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)enter:(id _Nullable)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enters the presence set for the channel, optionally passing a `data` payload. A `clientId` is required to be present on a channel. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param data The payload associated with the presence member.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)enter:(id _Nullable)data callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceEnter` event.
 *
 * @param data The payload to update for the presence member.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)update:(id _Nullable)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceEnter` event. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param data The payload to update for the presence member.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)update:(id _Nullable)data callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Leaves the presence set for the channel. A client must have previously entered the presence set before they can leave it.
 *
 * @param data The payload associated with the presence member.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)leave:(id _Nullable)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Leaves the presence set for the channel. A client must have previously entered the presence set before they can leave it. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param data The payload associated with the presence member.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)leave:(id _Nullable)data callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enters the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`.
 *
 * @param clientId The ID of the client to enter into the presence set.
 * @param data The payload associated with the presence member.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)enterClient:(NSString *)clientId data:(id _Nullable)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enters the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to enter into the presence set.
 * @param data The payload associated with the presence member.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)enterClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Updates the `data` payload for a presence member using a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`.
 *
 * @param clientId The ID of the client to update in the presence set.
 * @param data The payload to update for the presence member.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)updateClient:(NSString *)clientId data:(id _Nullable)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Updates the `data` payload for a presence member using a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to update in the presence set.
 * @param data The payload to update for the presence member.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)updateClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Leaves the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to leave the presence set for.
 * @param data The payload associated with the presence member.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Leaves the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to leave the presence set for.
 * @param data The payload associated with the presence member.
 * @param callback A success or failure callback function.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Registers a listener that is called each time a `ARTPresenceMessage` is received on the channel, such as a new member entering the presence set.
 *
 * @param callback An event listener function.
 *
 * @return An event listener object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceMessageCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Registers a listener that is called each time a `ARTPresenceMessage` is received on the channel, such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannel attach]` operation.
 *
 * @param onAttach An attach callback function.
 * @param callback An event listener function.
 *
 * @return An event listener object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Registers a listener that is called each time a `ARTPresenceMessage` matching a given `ARTPresenceAction` is received on the channel, such as a new member entering the presence set.
 *
 * @param action A `ARTPresenceAction` to register the listener for.
 * @param callback An event listener function.
 *
 * @return An event listener object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action callback:(ARTPresenceMessageCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Registers a listener that is called each time a `ARTPresenceMessage` matching a given `ARTPresenceAction` is received on the channel, such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannel attach]` operation.
 *
 * @param action A `ARTPresenceAction` to register the listener for.
 * @param onAttach An attach callback function.
 * @param callback An event listener function.
 *
 * @return An event listener object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action onAttach:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Deregisters all listeners currently receiving `ARTPresenceMessage` for the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribe;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Deregisters a specific listener that is registered to receive `ARTPresenceMessage` on the channel.
 *
 * @param An event listener to unsubscribe.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribe:(ARTEventListener *)listener;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Deregisters a specific listener that is registered to receive `ARTPresenceMessage` on the channel for a given `ARTPresenceAction`.
 *
 * @param action A specific `ARTPresenceAction` to deregister the listener for.
 * @param An event listener to unsubscribe.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener;

- (void)history:(ARTPaginatedPresenceCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTPresenceMessage` objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param query An `ARTRealtimeHistoryQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables the presence set to be entered and subscribed to, and the historic presence set to be retrieved for a channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTRealtimePresence : ARTPresence <ARTRealtimePresenceProtocol>
@end

NS_ASSUME_NONNULL_END
