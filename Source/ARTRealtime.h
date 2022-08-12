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
 * Retrieves a [`LocalDevice`]{@link LocalDevice} object that represents the current state of the device as a target for push notifications.
 *
 * @return A [`LocalDevice`]{@link LocalDevice} object.
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
 * Constructs a `RealtimeClient` object using an Ably [`ClientOptions`]{@link ClientOptions} object.
 *
 * @param options A [`ClientOptions`]{@link ClientOptions} object.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Instantiates the Ably library with the given options.
 * :param options: see ``ARTClientOptions`` for options
 * END LEGACY DOCSTRING
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 * BEGIN CANONICAL DOCSTRING
 * Constructs a `RealtimeClient` object using an Ably API key or token string.
 *
 * @param keyOrTokenStr The Ably API key or token string used to validate the client.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Instance the Ably library using a key only. This is simply a convenience constructor for the simplest case of instancing the library with a key for basic authentication and no other options.
 * :param key; String key (obtained from application dashboard)
 * END LEGACY DOCSTRING
 */
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)token;

- (void)time:(ARTDateTimeCallback)cb;
- (void)ping:(ARTCallback)cb;

- (BOOL)stats:(ARTPaginatedStatsCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Queries the REST `/stats` API and retrieves your application's usage statistics. Returns a [`PaginatedResult`]{@link PaginatedResult} object, containing an array of [`Stats`]{@link Stats} objects. See the [Stats docs](https://ably.com/docs/general/statistics).
 *
 * @param start The time from which stats are retrieved, specified as milliseconds since the Unix epoch.
 * @param end The time until stats are retrieved, specified as milliseconds since the Unix epoch.
 * @param direction The order for which stats are returned in. Valid values are `backwards` which orders stats from most recent to oldest, or `forwards` which orders stats from oldest to most recent. The default is `backwards`.
 * @param limit An upper limit on the number of stats returned. The default is 100, and the maximum is 1000.
 * @param unit `minute`, `hour`, `day` or `month`. Based on the unit selected, the given `start` or `end` times are rounded down to the start of the relevant interval depending on the unit granularity of the query.
 *
 * @return A [`PaginatedResult`]{@link PaginatedResult} object containing an array of [`Stats`]{@link Stats} objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(ARTPaginatedStatsCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)connect;
- (void)close;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * A client that extends the functionality of the [`RestClient`]{@link RestClient} and provides additional realtime-specific features.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * The top-level class to be instanced for the Ably Realtime library.
 * The Ably Realtime library will open and maintain a connection to the Ably realtime servers as soon as it is instantiated.
 * The ``ARTConnection`` object provides a straightforward API to monitor and manage connection state.
 * END LEGACY DOCSTRING
 */
@interface ARTRealtime : NSObject <ARTRealtimeProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Connection`]{@link Connection} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTConnection *connection;
/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Channels`]{@link Channels} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRealtimeChannels *channels;
/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Push`]{@link Push} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTPush *push;
/**
 * BEGIN CANONICAL DOCSTRING
 * An [`Auth`]{@link Auth} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTAuth *auth;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

@end

NS_ASSUME_NONNULL_END
