#import <Foundation/Foundation.h>

#import <Ably/ARTStatus.h>
#import <Ably/ARTEventEmitter.h>

@class ARTStatus;
@class ARTHttpResponse;
@class ARTErrorInfo;
@class ARTMessage;
@class ARTPresenceMessage;
@class ARTTokenParams;
@class ARTTokenRequest;
@class ARTTokenDetails;
@class ARTHTTPPaginatedResponse;
@class ARTPaginatedResult<ItemType>;
@class ARTStats;
@class ARTPushChannelSubscription;
@class ARTDeviceDetails;
@protocol ARTTokenDetailsCompatible;

// More context
typedef NSDictionary<NSString *, id> ARTJsonObject;
typedef NSString ARTDeviceId;
typedef NSString ARTDeviceSecret;
typedef NSData ARTDeviceToken;
typedef ARTJsonObject ARTPushRecipient;

typedef NS_ENUM(NSUInteger, ARTAuthentication) {
    ARTAuthenticationOff,
    ARTAuthenticationOn,
    ARTAuthenticationUseBasic,
    ARTAuthenticationNewToken,
    ARTAuthenticationTokenRetry
};

typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the realtime `ARTConnection` object states.
 * END CANONICAL PROCESSED DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionState) {
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A connection with this state has been initialized but no connection has yet been attempted.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeInitialized,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A connection attempt has been initiated. The connecting state is entered as soon as the library has completed initialization, and is reentered each time connection is re-attempted following disconnection.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeConnecting,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A connection exists and is active.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeConnected,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A temporary failure condition. No current connection exists because there is no network connectivity or no host is available. The disconnected state is entered if an established connection is dropped, or if a connection attempt was unsuccessful. In the disconnected state the library will periodically attempt to open a new connection (approximately every 15 seconds), anticipating that the connection will be re-established soon and thus connection and channel continuity will be possible. In this state, developers can continue to publish messages as they are automatically placed in a local queue, to be sent as soon as a connection is reestablished. Messages published by other clients while this client is disconnected will be delivered to it upon reconnection, so long as the connection was resumed within 2 minutes. After 2 minutes have elapsed, recovery is no longer possible and the connection will move to the `ARTRealtimeSuspended` state.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeDisconnected,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A long term failure condition. No current connection exists because there is no network connectivity or no host is available. The suspended state is entered after a failed connection attempt if there has then been no connection for a period of two minutes. In the suspended state, the library will periodically attempt to open a new connection every 30 seconds. Developers are unable to publish messages in this state. A new connection attempt can also be triggered by an explicit call to `-[ARTConnectionProtocol connect]`. Once the connection has been re-established, channels will be automatically re-attached. The client has been disconnected for too long for them to resume from where they left off, so if it wants to catch up on messages published by other clients while it was disconnected, it needs to use the [History API](https://ably.com/docs/realtime/history).
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeSuspended,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * An explicit request by the developer to close the connection has been sent to the Ably service. If a reply is not received from Ably within a short period of time, the connection is forcibly terminated and the connection state becomes `ARTRealtimeClosed`.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeClosing,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The connection has been explicitly closed by the client. In the closed state, no reconnection attempts are made automatically by the library, and clients may not publish messages. No connection state is preserved by the service or by the library. A new connection attempt can be triggered by an explicit call to `-[ARTConnectionProtocol connect]`, which results in a new connection.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeClosed,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * This state is entered if the client library encounters a failure condition that it cannot recover from. This may be a fatal connection error received from the Ably service, for example an attempt to connect with an incorrect API key, or a local terminal error, for example the token in use has expired and the library does not have any way to renew it. In the failed state, no reconnection attempts are made automatically by the library, and clients may not publish messages. A new connection attempt can be triggered by an explicit call to `-[ARTConnectionProtocol connect]`.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeFailed
};

NSString *_Nonnull ARTRealtimeConnectionStateToStr(ARTRealtimeConnectionState state);

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the events emitted by a `ARTConnection` object. An event is either an `ARTRealtimeConnectionEventUpdate` or an `ARTRealtimeConnectionState`.
 * END CANONICAL PROCESSED DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionEvent) {
    ARTRealtimeConnectionEventInitialized,
    ARTRealtimeConnectionEventConnecting,
    ARTRealtimeConnectionEventConnected,
    ARTRealtimeConnectionEventDisconnected,
    ARTRealtimeConnectionEventSuspended,
    ARTRealtimeConnectionEventClosing,
    ARTRealtimeConnectionEventClosed,
    ARTRealtimeConnectionEventFailed,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * An event for changes to connection conditions for which the `ARTRealtimeConnectionState` does not change.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeConnectionEventUpdate
};

NSString *_Nonnull ARTRealtimeConnectionEventToStr(ARTRealtimeConnectionEvent event);

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the possible states of an `ARTRealtimeChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTRealtimeChannelState) {
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The channel has been initialized but no attach has yet been attempted.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelInitialized,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * An attach has been initiated by sending a request to Ably. This is a transient state, followed either by a transition to `ARTRealtimeChannelAttached`, `ARTRealtimeChannelSuspended`, or `ARTRealtimeChannelFailed`.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelAttaching,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The attach has succeeded. In the attached state a client may publish and subscribe to messages, or be present on the channel.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelAttached,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A detach has been initiated on an `ARTRealtimeChannelAttached` channel by sending a request to Ably. This is a transient state, followed either by a transition to `ARTRealtimeChannelDetached` or `ARTRealtimeChannelFailed`.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelDetaching,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The channel, having previously been `ARTRealtimeChannelAttached`, has been detached by the user.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelDetached,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The channel, having previously been `ARTRealtimeChannelAttached`, has lost continuity, usually due to the client being disconnected from Ably for longer than two minutes. It will automatically attempt to reattach as soon as connectivity is restored.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelSuspended,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * An indefinite failure condition. This state is entered if a channel error has been received from the Ably service, such as an attempt to attach without the necessary access rights.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTRealtimeChannelFailed
};

NSString *_Nonnull ARTRealtimeChannelStateToStr(ARTRealtimeChannelState state);

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the events emitted by an `ARTRealtimeChannel` object. An event is either an `ARTChannelEventUpdate` or a `ARTRealtimeChannelState`.
 * END CANONICAL PROCESSED DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTChannelEvent) {
    ARTChannelEventInitialized,
    ARTChannelEventAttaching,
    ARTChannelEventAttached,
    ARTChannelEventDetaching,
    ARTChannelEventDetached,
    ARTChannelEventSuspended,
    ARTChannelEventFailed,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * An event for changes to channel conditions that do not result in a change in `ARTRealtimeChannelState`.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTChannelEventUpdate
};

NSString *_Nonnull ARTChannelEventToStr(ARTChannelEvent event);


typedef NS_ENUM(NSInteger, ARTDataQueryError) {
    ARTDataQueryErrorLimit = 1,
    ARTDataQueryErrorTimestampRange = 2,
    ARTDataQueryErrorMissingRequiredFields = 3,
    ARTDataQueryErrorInvalidParameters = 4,
    ARTDataQueryErrorDeviceInactive = 5,
};

typedef NS_ENUM(NSInteger, ARTRealtimeHistoryError) {
    ARTRealtimeHistoryErrorNotAttached = ARTDataQueryErrorTimestampRange + 1
};

typedef NS_ENUM(NSInteger, ARTCustomRequestError) {
    ARTCustomRequestErrorInvalidMethod = 1,
    ARTCustomRequestErrorInvalidBody = 2,
    ARTCustomRequestErrorInvalidPath = 3,
};

NS_ASSUME_NONNULL_BEGIN

/// Decompose API key
NSArray<NSString *> *decomposeKey(NSString *key);

NSString *encodeBase64(NSString *value);
NSString *decodeBase64(NSString *base64);

uint64_t dateToMilliseconds(NSDate *date);
uint64_t timeIntervalToMilliseconds(NSTimeInterval seconds);
NSTimeInterval millisecondsToTimeInterval(uint64_t msecs);

NSString *generateNonce(void);

/// :nodoc:
@protocol ARTCancellable
- (void)cancel;
@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains `ARTRealtimeConnectionState` change information emitted by the `ARTConnection` object.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * ARTConnectionStateChange is a type encapsulating state change information emitted by the `ARTConnection` object. See `-[ARTConnection on:]` to register a listener for one or more events.
 * END LEGACY DOCSTRING
 */
@interface ARTConnectionStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason
                        retryIn:(NSTimeInterval)retryIn;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The new `ARTRealtimeConnectionState`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) ARTRealtimeConnectionState current;
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The previous `ARTRealtimeConnectionState`. For the `ARTRealtimeConnectionEventUpdate` event, this is equal to the `-[ARTRealtimeConnectionState current]` state.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) ARTRealtimeConnectionState previous;
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The event that triggered this `ARTRealtimeConnectionState` change.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) ARTRealtimeConnectionEvent event;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTErrorInfo` object containing any information relating to the transition.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic, nullable) ARTErrorInfo *reason;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Duration in milliseconds, after which the client retries a connection where applicable.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSTimeInterval retryIn;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains state change information emitted by an `ARTRealtimeChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTChannelStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeChannelState)current
                       previous:(ARTRealtimeChannelState)previous
                          event:(ARTChannelEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeChannelState)current
                       previous:(ARTRealtimeChannelState)previous
                          event:(ARTChannelEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason
                        resumed:(BOOL)resumed;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The new current `ARTRealtimeChannelState`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) ARTRealtimeChannelState current;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The previous state. For the `ARTChannelEventUpdate` event, this is equal to the `-[ARTRealtimeChannelState current]` state.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) ARTRealtimeChannelState previous;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The event that triggered this `ARTRealtimeChannelState` change.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) ARTChannelEvent event;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTErrorInfo` object containing any information relating to the transition.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic, nullable) ARTErrorInfo *reason;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Indicates whether message continuity on this channel is preserved, see [Nonfatal channel errors](https://ably.com/docs/realtime/channels#nonfatal-errors) for more info.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) BOOL resumed;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the metrics associated with a `ARTRestChannel` or `ARTRealtimeChannel`, such as the number of publishers, subscribers and connections it has.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTChannelMetrics : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of realtime connections attached to the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger connections;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of realtime attachments permitted to publish messages to the channel. This requires the `publish` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelModePublish`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger publishers;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of realtime attachments receiving messages on the channel. This requires the `subscribe` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelModeSubscribe`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger subscribers;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of realtime connections attached to the channel with permission to enter the presence set, regardless of whether or not they have entered it. This requires the `presence` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelModePresence`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger presenceConnections;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of members in the presence set of the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger presenceMembers;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of realtime attachments receiving presence messages on the channel. This requires the `subscribe` capability and for a client to not have specified a `ARTChannelMode` flag that excludes `ARTChannelModePresenceSubscribe`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger presenceSubscribers;

- (instancetype)initWithConnections:(NSInteger)connections
                         publishers:(NSInteger)publishers
                        subscribers:(NSInteger)subscribers
                presenceConnections:(NSInteger)presenceConnections
                    presenceMembers:(NSInteger)presenceMembers
                presenceSubscribers:(NSInteger)presenceSubscribers;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the metrics of a `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTChannelOccupancy : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTChannelMetrics` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, readonly) ARTChannelMetrics *metrics;

- (instancetype)initWithMetrics:(ARTChannelMetrics *)metrics;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the status of a `ARTRestChannel` or `ARTRealtimeChannel` object such as whether it is active and its `ARTChannelOccupancy`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTChannelStatus : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * If `true`, the channel is active, otherwise `false`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) BOOL active;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTChannelOccupancy` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, readonly) ARTChannelOccupancy *occupancy;

- (instancetype)initWithOccupancy:(ARTChannelOccupancy *)occupancy active:(BOOL)active;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the details of a `ARTRestChannel` or `ARTRealtimeChannel` object such as its ID and `ARTChannelStatus`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTChannelDetails : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The identifier of the channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, readonly) NSString *channelId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTChannelStatus` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, readonly) ARTChannelStatus *status;

- (instancetype)initWithChannelId:(NSString *)channelId status:(ARTChannelStatus *)status;

@end

/// :nodoc:
@protocol ARTJsonCompatible <NSObject>
- (NSDictionary *_Nullable)toJSON:(NSError *_Nullable *_Nullable)error;
- (NSString *_Nullable)toJSONString;
@end

/// :nodoc:
@interface NSString (ARTEventIdentification) <ARTEventIdentification>
@end

/// :nodoc:
@interface NSString (ARTJsonCompatible) <ARTJsonCompatible>
@end

/// :nodoc:
@interface NSString (ARTUtilities)
- (NSString *)art_shortString NS_SWIFT_NAME(shortString());
- (NSString *)art_base64Encoded NS_SWIFT_NAME(base64Encoded());
@end

/// :nodoc:
@interface NSDate (ARTUtilities)
+ (NSDate *)art_dateWithMillisecondsSince1970:(uint64_t)msecs NS_SWIFT_NAME(date(withMillisecondsSince1970:));
@end

/// :nodoc:
@interface NSDictionary (ARTJsonCompatible) <ARTJsonCompatible>
@end

/// :nodoc:
@interface NSURL (ARTLog)
@end

/// :nodoc:
@interface NSDictionary (ARTURLQueryItemAdditions)
@property (nonatomic, readonly) NSArray<NSURLQueryItem *> *art_asURLQueryItems;
@end

/// :nodoc:
@interface NSMutableArray (ARTQueueAdditions)
- (void)art_enqueue:(id)object;
- (nullable id)art_dequeue;
- (nullable id)art_peek;
@end

/// :nodoc:
@interface NSObject (ARTArchive)
- (nullable NSData *)art_archive;
+ (nullable id)art_unarchiveFromData:(NSData *)data;
@end

/// :nodoc:
@interface NSURLSessionTask (ARTCancellable) <ARTCancellable>
@end

typedef NSDictionary<NSString *, NSString *> NSStringDictionary;

/**
 Signatures of completion handlers to improve readability and maintainability in properties and method parameters.
 Either result/response or error can be nil but not both.
 */
typedef void (^ARTCallback)(ARTErrorInfo *_Nullable error);
typedef void (^ARTResultCallback)(id _Nullable result, NSError *_Nullable error);
typedef void (^ARTDateTimeCallback)(NSDate *_Nullable result, NSError *_Nullable error);

typedef void (^ARTMessageCallback)(ARTMessage *message);
typedef void (^ARTChannelStateCallback)(ARTChannelStateChange *stateChange);
typedef void (^ARTConnectionStateCallback)(ARTConnectionStateChange *stateChange);
typedef void (^ARTPresenceMessageCallback)(ARTPresenceMessage *message);
typedef void (^ARTPresenceMessagesCallback)(NSArray<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error);
typedef void (^ARTChannelDetailsCallback)(ARTChannelDetails *_Nullable details, ARTErrorInfo *_Nullable error);

typedef void (^ARTStatusCallback)(ARTStatus *status);
typedef void (^ARTURLRequestCallback)(NSHTTPURLResponse *_Nullable result, NSData *_Nullable data, NSError *_Nullable error);
typedef void (^ARTTokenDetailsCallback)(ARTTokenDetails *_Nullable result, NSError *_Nullable error);
typedef void (^ARTTokenDetailsCompatibleCallback)(id<ARTTokenDetailsCompatible> _Nullable result, NSError *_Nullable error);
typedef void (^ARTAuthCallback)(ARTTokenParams *params, ARTTokenDetailsCompatibleCallback callback);

typedef void (^ARTHTTPPaginatedCallback)(ARTHTTPPaginatedResponse *_Nullable response, ARTErrorInfo *_Nullable error);
typedef void (^ARTPaginatedStatsCallback)(ARTPaginatedResult<ARTStats *> *_Nullable result, ARTErrorInfo *_Nullable error);
typedef void (^ARTPaginatedPresenceCallback)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error);
typedef void (^ARTPaginatedPushChannelCallback)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable result, ARTErrorInfo *_Nullable error);
typedef void (^ARTPaginatedMessagesCallback)(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error);
typedef void (^ARTPaginatedDeviceDetailsCallback)(ARTPaginatedResult<ARTDeviceDetails *> *_Nullable result, ARTErrorInfo *_Nullable error);
typedef void (^ARTPaginatedTextCallback)(ARTPaginatedResult<NSString *> *_Nullable result, ARTErrorInfo *_Nullable error);

/**
 Wraps the given callback in an ARTCancellable, offering the following
 protections:
 
 1) If the cancel method is called on the returned instance then the callback
    will not be invoked.
 2) The callback will only ever be invoked once.
 
 To make use of these benefits the caller needs to use the returned wrapper
 to invoke the callback. The wrapper will only work for as long as the returned
 instance remains allocated (i.e. has a strong reference to it somewhere).
 */
NSObject<ARTCancellable> * artCancellableFromCallback(ARTResultCallback callback, _Nonnull ARTResultCallback *_Nonnull wrapper);

NS_ASSUME_NONNULL_END
