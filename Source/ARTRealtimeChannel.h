#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>
#import <Ably/ARTRestChannel.h>
#import <Ably/ARTPresenceMessage.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimePresence.h>
#import <Ably/ARTDataQuery.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRealtimePresence;
@class ARTRealtimeChannelOptions;
#if TARGET_OS_IPHONE
@class ARTPushChannel;
#endif

@protocol ARTRealtimeChannelProtocol <ARTChannelProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * The current [`ChannelState`]{@link ChannelState} of the channel.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimeChannelState state;

/**
 * BEGIN CANONICAL DOCSTRING
 * An [`ErrorInfo`]{@link ErrorInfo} object describing the last error which occurred on the channel, if any.
 * END CANONICAL DOCSTRING
 */
@property (readonly, nullable) ARTErrorInfo *errorReason;
@property (readonly, nullable, getter=getOptions) ARTRealtimeChannelOptions *options;

- (void)attach;

/**
 * BEGIN CANONICAL DOCSTRING
 * Attach to this channel ensuring the channel is created in the Ably system and all messages published on the channel are received by any channel listeners registered using [`subscribe()`]{@link RealtimeChannel#subscribe}. Any resulting channel state change will be emitted to any listeners registered using the [`on()`]{@link EventEmitter#on} or [`once()`]{@link EventEmitter#once} methods. A callback may optionally be passed in to this call to be notified of success or failure of the operation. As a convenience, `attach()` is called implicitly if [`subscribe()`]{@link RealtimeChannel#subscribe} for the channel is called, or [`enter()`]{@link RealtimePresence#enter} or [`subscribe()`]{@link RealtimePresence#subscribe} are called on the [`RealtimePresence`]{@link RealtimePresence} object for this channel.
 * END CANONICAL DOCSTRING
 */
- (void)attach:(nullable ARTCallback)callback;

- (void)detach;

/**
 * BEGIN CANONICAL DOCSTRING
 * Detach from this channel. Any resulting channel state change is emitted to any listeners registered using the [`on()`]{@link EventEmitter#on} or [`once()`]{@link EventEmitter#once} methods. A callback may optionally be passed in to this call to be notified of success or failure of the operation. Once all clients globally have detached from the channel, the channel will be released in the Ably service within two minutes.
 * END CANONICAL DOCSTRING
 */
- (void)detach:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener for messages on this channel. The caller supplies a listener function, which is called each time one or more messages arrives on the channel. A callback may optionally be passed in to this call to be notified of success or failure of the channel [`attach()`]{@link RealtimeChannel#attach} operation.
 *
 * @param callback An event listener function.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTMessageCallback)callback;
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(ARTMessageCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener for messages with a given event name on this channel. The caller supplies a listener function, which is called each time one or more matching messages arrives on the channel. A callback may optionally be passed in to this call to be notified of success or failure of the channel [`attach()`]{@link RealtimeChannel#attach} operation.
 *
 * @param name The event name.
 * @param callback An event listener function.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(NSString *)name callback:(ARTMessageCallback)cb;
- (ARTEventListener *_Nullable)subscribe:(NSString *)name onAttach:(nullable ARTCallback)onAttach callback:(ARTMessageCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters all listeners to messages on this channel. This removes all earlier subscriptions.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters the given listener (for any/all event names). This removes an earlier subscription.
 *
 * @param listener An event listener function.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe:(ARTEventListener *_Nullable)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters the given listener for the specified event name. This removes an earlier event-specific subscription.
 *
 * @param name The event name.
 * @param listener An event listener function.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe:(NSString *)name listener:(ARTEventListener *_Nullable)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a [`PaginatedResult`]{@link PaginatedResult} object, containing an array of historical [`Message`]{@link Message} objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param start The time from which messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param end The time until messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param direction The order for which messages are returned in. Valid values are `backwards` which orders messages from most recent to oldest, or `forwards` which orders messages from oldest to most recent. The default is `backwards`.
 * @param limit An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 * @param untilAttach When `true`, ensures message history is up until the point of the channel being attached. See [continuous history](https://ably.com/docs/realtime/history#continuous-history) for more info. Requires the `direction` to be `backwards`. If the channel is not attached, or if `direction` is set to `forwards`, this option results in an error.
 *
 * @return A [`PaginatedResult`]{@link PaginatedResult} object containing an array of [`Message`]{@link Message} objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL DOCSTRING
 * Sets the [`ChannelOptions`]{@link ChannelOptions} for the channel.
 *
 * @param options A [`ChannelOptions`]{@link ChannelOptions} object.
 * END CANONICAL DOCSTRING
 */
- (void)setOptions:(ARTRealtimeChannelOptions *_Nullable)options callback:(nullable ARTCallback)cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * `RealtimeChannel` implements [`EventEmitter`]{@link EventEmitter} and emits [`ChannelEvent`]{@link ChannelEvent} events, where a `ChannelEvent` is either a [`ChannelState`]{@link ChannelState} or an [`UPDATE`]{@link ChannelEvent#UPDATE}.
 * END CANONICAL DOCSTRING
 */
ART_EMBED_INTERFACE_EVENT_EMITTER(ARTChannelEvent, ARTChannelStateChange *)

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables messages to be published and subscribed to. Also enables historic messages to be retrieved and provides access to the [`RealtimePresence`]{@link RealtimePresence} object of a channel.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTRealtimeChannel provides a straightforward API for publishing and subscribing to messages on a channel. In order to publish, subscribe to, or be present on a channel, you must first obtain a channel instance via ``ARTRealtime/channels/get``.
 * END LEGACY DOCSTRING
 */
@interface ARTRealtimeChannel : NSObject <ARTRealtimeChannelProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`RealtimePresence`]{@link RealtimePresence} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimePresence *presence;
#if TARGET_OS_IPHONE
/**
 * BEGIN CANONICAL DOCSTRING
 * A [`PushChannel`]{@link PushChannel} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTPushChannel *push;
#endif

@end

#pragma mark - ARTEvent

@interface ARTEvent (ChannelEvent)
- (instancetype)initWithChannelEvent:(ARTChannelEvent)value;
+ (instancetype)newWithChannelEvent:(ARTChannelEvent)value;
@end

NS_ASSUME_NONNULL_END
