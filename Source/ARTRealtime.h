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
@property (readonly) ARTLocalDevice *device;
#endif
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

@property (readonly) ARTConnection *connection;
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
