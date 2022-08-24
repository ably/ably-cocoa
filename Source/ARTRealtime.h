#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>
#import <Ably/ARTRealtimeChannels.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTConnection.h>

@class ARTStatus;
@class ARTMessage;
@class ARTClientOptions;
@class ARTStatsQuery;
@class ARTRealtimeChannel;
@class ARTPresenceMessage;
@class ARTErrorInfo;
@class ARTCipherParams;
@class ARTPresence;
@class ARTPresenceMap;
@class ARTEventEmitter;
@class ARTRealtimeChannel;
@class ARTAuth;
@class ARTPush;
@class ARTProtocolMessage;
@class ARTRealtimeChannels;

NS_ASSUME_NONNULL_BEGIN

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

#pragma mark - ARTRealtime

/**
 The protocol upon which the top level object ``ARTRealtime`` is implemented.
 */
@protocol ARTRealtimeProtocol <NSObject>

#if TARGET_OS_IOS
/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a `ARTLocalDevice` object that represents the current state of the device as a target for push notifications.
 *
 * @return A `ARTLocalDevice` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTLocalDevice *device;
#endif

/**
 * BEGIN CANONICAL DOCSTRING
 * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. A `clientId` may also be implicit in a token used to instantiate the library; an error will be raised if a `clientId` specified here conflicts with the `clientId` implicit in the token.
 * END CANONICAL DOCSTRING
 */
@property (readonly, nullable) NSString *clientId;

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Constructs a `RealtimeClient` object using an Ably `ARTClientOptions` object.
 *
 * @param options A `ARTClientOptions` object.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 * BEGIN CANONICAL DOCSTRING
 * Constructs a `RealtimeClient` object using an Ably API key or token string.
 *
 * @param keyOrTokenStr The Ably API key or token string used to validate the client.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)token;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves the time from the Ably service as milliseconds since the Unix epoch. Clients that do not have access to a sufficiently well maintained time source and wish to issue Ably `ARTTokenRequest`s with a more accurate timestamp should use the `ARTClientOptions.queryTime` property instead of this method.
 *
 * @return The time as milliseconds since the Unix epoch.
 * END CANONICAL DOCSTRING
 */
- (void)time:(ARTDateTimeCallback)cb;
- (void)ping:(ARTCallback)cb;

- (BOOL)stats:(ARTPaginatedStatsCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Queries the REST `/stats` API and retrieves your application's usage statistics. Returns a `ARTPaginatedResult` object, containing an array of `ARTStats` objects. See the [Stats docs](https://ably.com/docs/general/statistics).
 *
 * @param start The time from which stats are retrieved, specified as milliseconds since the Unix epoch.
 * @param end The time until stats are retrieved, specified as milliseconds since the Unix epoch.
 * @param direction The order for which stats are returned in. Valid values are `backwards` which orders stats from most recent to oldest, or `forwards` which orders stats from oldest to most recent. The default is `backwards`.
 * @param limit An upper limit on the number of stats returned. The default is 100, and the maximum is 1000.
 * @param unit `minute`, `hour`, `day` or `month`. Based on the unit selected, the given `start` or `end` times are rounded down to the start of the relevant interval depending on the unit granularity of the query.
 *
 * @return A `ARTPaginatedResult` object containing an array of `ARTStats` objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(ARTPaginatedStatsCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL DOCSTRING
 * Calls `-[ARTConnection connect]` and causes the connection to open, entering the connecting state. Explicitly calling `connect()` is unnecessary unless the `ARTClientOptions.autoConnect` property is disabled.
 * END CANONICAL DOCSTRING
 */
- (void)connect;

/**
 * BEGIN CANONICAL DOCSTRING
 * Calls `-[ARTConnection close]` and causes the connection to close, entering the closing state. Once closed, the library will not attempt to re-establish the connection without an explicit call to `-[ARTConnection connect]`.
 * END CANONICAL DOCSTRING
 */
- (void)close;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * A client that extends the functionality of the `ARTRestClient` and provides additional realtime-specific features.
 * END CANONICAL DOCSTRING
 */
@interface ARTRealtime : NSObject <ARTRealtimeProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * A `ARTConnection` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTConnection *connection;
/**
 * BEGIN CANONICAL DOCSTRING
 * A `ARTChannels` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimeChannels *channels;
/**
 * BEGIN CANONICAL DOCSTRING
 * A `ARTPush` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTPush *push;
/**
 * BEGIN CANONICAL DOCSTRING
 * An `ARTAuth` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTAuth *auth;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

@end

NS_ASSUME_NONNULL_END
