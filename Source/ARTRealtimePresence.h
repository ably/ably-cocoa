#import <Foundation/Foundation.h>

#import <Ably/ARTRestPresence.h>
#import <Ably/ARTDataQuery.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceQuery : ARTPresenceQuery

@property (readwrite, nonatomic) BOOL waitForSync;

@end

@protocol ARTRealtimePresenceProtocol

/**
 * BEGIN CANONICAL DOCSTRING
 * Indicates whether the presence set synchronization between Ably and the clients on the channel has been completed. Set to `true` when the sync is complete.
 * END CANONICAL DOCSTRING
 */
@property (readonly) BOOL syncComplete;

- (void)get:(ARTPresenceMessagesCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves the current members present on the channel and the metadata for each member, such as their [`PresenceAction`]{@link PresenceAction} and ID. Returns an array of [`PresenceMessage`]{@link PresenceMessage} objects.
 *
 * @param waitForSync Sets whether to wait for a full presence set synchronization between Ably and the clients on the channel to complete before returning the results. Synchronization begins as soon as the channel is [`ATTACHED`]{@link ChannelState#ATTACHED}. When set to `true` the results will be returned as soon as the sync is complete. When set to `false` the current list of members will be returned without the sync completing. The default is `true`.
 * @param clientId Filters the array of returned presence members by a specific client using its ID.
 * @param connectionId Filters the array of returned presence members by a specific connection using its ID.
 *
 * @return An array of [`PresenceMessage`]{@link PresenceMessage} objects.
 * END CANONICAL DOCSTRING
 */
- (void)get:(ARTRealtimePresenceQuery *)query callback:(ARTPresenceMessagesCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enters the presence set for the channel, optionally passing a `data` payload. A `clientId` is required to be present on a channel. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param data The payload associated with the presence member.
 * @param extras A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL DOCSTRING
 */
- (void)enter:(id _Nullable)data;
- (void)enter:(id _Nullable)data callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an [`ENTER`]{@link PresenceAction#ENTER} event. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param data The payload to update for the presence member.
 * @param extras A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL DOCSTRING
 */
- (void)update:(id _Nullable)data;
- (void)update:(id _Nullable)data callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Leaves the presence set for the channel. A client must have previously entered the presence set before they can leave it. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param data The payload associated with the presence member.
 * @param extras A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL DOCSTRING
 */
- (void)leave:(id _Nullable)data;
- (void)leave:(id _Nullable)data callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enters the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to enter into the presence set.
 * @param data The payload associated with the presence member.
 * @param extras A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL DOCSTRING
 */
- (void)enterClient:(NSString *)clientId data:(id _Nullable)data;
- (void)enterClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Updates the `data` payload for a presence member using a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to update in the presence set.
 * @param data The payload to update for the presence member.
 * @param extras A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL DOCSTRING
 */
- (void)updateClient:(NSString *)clientId data:(id _Nullable)data;
- (void)updateClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Leaves the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param clientId The ID of the client to leave the presence set for.
 * @param data The payload associated with the presence member.
 * @param extras A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL DOCSTRING
 */
- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data;
- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener that is called each time a [`PresenceMessage`]{@link PresenceMessage} is received on the channel, such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified of success or failure of the channel [`attach()`]{@link RealtimeChannel#attach} operation.
 *
 * @return An event listener function.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceMessageCallback)callback;
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener that is called each time a [`PresenceMessage`]{@link PresenceMessage} matching a given [`PresenceAction`]{@link PresenceAction}, or an action within an array of [`PresenceAction`s]{@link PresenceAction}, is received on the channel, such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified of success or failure of the channel [`attach()`]{@link RealtimeChannel#attach} operation.
 *
 * @param action A [`PresenceAction`]{@link PresenceAction} or an array of [`PresenceAction`s]{@link PresenceAction} to register the listener for.
 *
 * @return An event listener function.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action callback:(ARTPresenceMessageCallback)cb;
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action onAttach:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters all listeners currently receiving [`PresenceMessage`]{@link PresenceMessage} for the channel.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters a specific listener that is registered to receive [`PresenceMessage`]{@link PresenceMessage} on the channel.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe:(ARTEventListener *)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters a specific listener that is registered to receive [`PresenceMessage`]{@link PresenceMessage} on the channel for a given [`PresenceAction`]{@link PresenceAction}.
 *
 * @param action A specific [`PresenceAction`]{@link PresenceAction} to deregister the listener for.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener;

- (void)history:(ARTPaginatedPresenceCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a [`PaginatedResult`]{@link PaginatedResult} object, containing an array of historical [`PresenceMessage`]{@link PresenceMessage} objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param start The time from which messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param end The time until messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param direction The order for which messages are returned in. Valid values are `backwards` which orders messages from most recent to oldest, or `forwards` which orders messages from oldest to most recent. The default is `backwards`.
 * @param limit An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 *
 * @return A [`PaginatedResult`]{@link PaginatedResult} object containing an array of [`PresenceMessage`]{@link PresenceMessage} objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables the presence set to be entered and subscribed to, and the historic presence set to be retrieved for a channel.
 * END CANONICAL DOCSTRING
 */
@interface ARTRealtimePresence : ARTPresence <ARTRealtimePresenceProtocol>
@end

NS_ASSUME_NONNULL_END
