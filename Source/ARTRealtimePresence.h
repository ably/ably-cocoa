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

- (void)enter:(id _Nullable)data;
- (void)enter:(id _Nullable)data callback:(nullable ARTCallback)cb;

- (void)update:(id _Nullable)data;
- (void)update:(id _Nullable)data callback:(nullable ARTCallback)cb;

- (void)leave:(id _Nullable)data;
- (void)leave:(id _Nullable)data callback:(nullable ARTCallback)cb;

- (void)enterClient:(NSString *)clientId data:(id _Nullable)data;
- (void)enterClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb;

- (void)updateClient:(NSString *)clientId data:(id _Nullable)data;
- (void)updateClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb;

- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data;
- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb;

- (ARTEventListener *_Nullable)subscribe:(ARTPresenceMessageCallback)callback;
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb;
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action callback:(ARTPresenceMessageCallback)cb;
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action onAttach:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb;

- (void)unsubscribe;
- (void)unsubscribe:(ARTEventListener *)listener;
- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener;

- (void)history:(ARTPaginatedPresenceCallback)callback;
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
