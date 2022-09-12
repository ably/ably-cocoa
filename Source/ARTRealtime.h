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

/**
 The protocol upon which the top level object `ARTRealtime` is implemented.
 */
@protocol ARTRealtimeProtocol <NSObject>

#if TARGET_OS_IOS
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves a `ARTLocalDevice` object that represents the current state of the device as a target for push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTLocalDevice *device;
#endif

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. A `clientId` may also be implicit in a token used to instantiate the library; an error will be raised if a `clientId` specified here conflicts with the `clientId` implicit in the token.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nullable) NSString *clientId;

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Constructs an `ARTRealtime` object using an Ably `ARTClientOptions` object.
 *
 * @param options An `ARTClientOptions` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Constructs an `ARTRealtime` object using an Ably API key.
 *
 * @param key The Ably API key used to validate the client.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (instancetype)initWithKey:(NSString *)key;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Constructs an `ARTRealtime` object using an Ably token string.
 *
 * @param token The Ably token string used to validate the client.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (instancetype)initWithToken:(NSString *)token;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves the time from the Ably service. Clients that do not have access to a sufficiently well maintained time source and wish to issue Ably `ARTTokenRequest`s with a more accurate timestamp should use the `-[ARTClientOptions queryTime]` property instead of this method.
 *
 * @param callback A callback for receiving the time as a `NSDate` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)time:(ARTDateTimeCallback)callback;

/// :nodoc: TODO: docstring
- (void)ping:(ARTCallback)cb;

/// :nodoc: TODO: docstring
- (BOOL)stats:(ARTPaginatedStatsCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Queries the REST `/stats` API and retrieves your application's usage statistics. Returns a `ARTPaginatedResult` object, containing an array of `ARTStats` objects. See the [Stats docs](https://ably.com/docs/general/statistics).
 *
 * @param query An `ARTStatsQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTStats` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(ARTPaginatedStatsCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Calls `-[ARTConnectionProtocol connect]` and causes the connection to open, entering the connecting state. Explicitly calling `connect` is unnecessary unless the `ARTClientOptions.autoConnect` property is disabled.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)connect;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Calls `-[ARTConnection close]` and causes the connection to close, entering the closing state. Once closed, the library will not attempt to re-establish the connection without an explicit call to `connect`.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)close;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A client that extends the functionality of the `ARTRest` and provides additional realtime-specific features.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTRealtime : NSObject <ARTRealtimeProtocol>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTConnection` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTConnection *connection;
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTChannels` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTRealtimeChannels *channels;
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTPush` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTPush *push;
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTAuth` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTAuth *auth;

/// :nodoc:
+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

/// :nodoc:
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

/// :nodoc:
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

@end

NS_ASSUME_NONNULL_END
