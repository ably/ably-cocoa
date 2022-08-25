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
 * The current `ARTRealtimeChannelState` of the channel.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimeChannelState state;

/**
 * BEGIN CANONICAL DOCSTRING
 * An `ARTErrorInfo` object describing the last error which occurred on the channel, if any.
 * END CANONICAL DOCSTRING
 */
@property (readonly, nullable) ARTErrorInfo *errorReason;
@property (readonly, nullable, getter=getOptions) ARTRealtimeChannelOptions *options;

- (void)attach;

/**
 * BEGIN CANONICAL DOCSTRING
 * Attach to this channel ensuring the channel is created in the Ably system and all messages published on the channel are received by any channel listeners registered using `-[ARTRealtimeChannelProtocol subscribe:]`. Any resulting channel state change will be emitted to any listeners registered using the `-[ARTEventEmitter on:]` or `-[ARTEventEmitter once:]` methods. A callback may optionally be passed in to this call to be notified of success or failure of the operation. As a convenience, `-[ARTRealtimeChannelProtocol attach:]` is called implicitly if `-[ARTRealtimeChannelProtocol subscribe:]` for the channel is called, or `-[ARTRealtimePresenceProtocol enter:]` or `-[ARTRealtimePresenceProtocol subscribe:]` are called on the `ARTRealtimePresence` object for this channel.
 * END CANONICAL DOCSTRING
 */
- (void)attach:(nullable ARTCallback)callback;

- (void)detach;

/**
 * BEGIN CANONICAL DOCSTRING
 * Detach from this channel. Any resulting channel state change is emitted to any listeners registered using the `-[ARTEventEmitter on:]` or `-[ARTEventEmitter once:]` methods. A callback may optionally be passed in to this call to be notified of success or failure of the operation. Once all clients globally have detached from the channel, the channel will be released in the Ably service within two minutes.
 * END CANONICAL DOCSTRING
 */
- (void)detach:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener for messages on this channel. The caller supplies a listener function, which is called each time one or more messages arrives on the channel.
 *
 * @param callback An event listener function.
 *
 * @return An `ARTEventListener` object.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(ARTMessageCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener for messages on this channel. The caller supplies a listener function, which is called each time one or more messages arrives on the channel.
 * An attach callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannel attach]` operation.
 *
 * @param onAttach An attach callback function.
 * @param callback An event listener function.
 *
 * @return An `ARTEventListener` object.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(ARTMessageCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener for messages with a given event `name` on this channel. The caller supplies a listener function, which is called each time one or more matching messages arrives on the channel.
 *
 * @param name The event name.
 * @param callback An event listener function.
 *
 * @return An `ARTEventListener` object.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(NSString *)name callback:(ARTMessageCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers a listener for messages with a given event `name` on this channel. The caller supplies a listener function, which is called each time one or more matching messages arrives on the channel. A callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannel attach]` operation.
 *
 * @param name The event name.
 * @param callback An event listener function.
 *
 * @return An `ARTEventListener` object.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *_Nullable)subscribe:(NSString *)name onAttach:(nullable ARTCallback)onAttach callback:(ARTMessageCallback)callback;

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
 * @param listener An event listener object to unsubscribe.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe:(ARTEventListener *_Nullable)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters the given listener for the specified event name. This removes an earlier event-specific subscription.
 *
 * @param name The event name.
 * @param listener An event listener object to unsubscribe.
 * END CANONICAL DOCSTRING
 */
- (void)unsubscribe:(NSString *)name listener:(ARTEventListener *_Nullable)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves an `ARTPaginatedResult` object, containing an array of historical `ARTMessage` objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param query An `ARTRealtimeHistoryQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL DOCSTRING
 */
- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL DOCSTRING
 * Sets the `-[ARTRealtimeChannelProtocol options]` for the channel. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param options An `ARTRealtimeChannelOptions` object.
 * @param callback A success or failure callback function.
 * END CANONICAL DOCSTRING
 */
- (void)setOptions:(ARTRealtimeChannelOptions *_Nullable)options callback:(nullable ARTCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * `ARTRealtimeChannel` implements `ARTEventEmitter` and emits `ARTChannelEvent` events, where a `ARTChannelEvent` is either a `ARTRealtimeChannelState` or an `ARTChannelEventUpdate`.
 * END CANONICAL DOCSTRING
 */
ART_EMBED_INTERFACE_EVENT_EMITTER(ARTChannelEvent, ARTChannelStateChange *)

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables messages to be published and subscribed to. Also enables historic messages to be retrieved and provides access to the `ARTRealtimePresence` object of a channel.
 * END CANONICAL DOCSTRING
 */
@interface ARTRealtimeChannel : NSObject <ARTRealtimeChannelProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * An `ARTRealtimePresence` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimePresence *presence;
#if TARGET_OS_IPHONE
/**
 * BEGIN CANONICAL DOCSTRING
 * An `ARTPushChannel` object.
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
