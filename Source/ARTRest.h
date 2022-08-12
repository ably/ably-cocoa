#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>
#import <Ably/ARTRestChannels.h>
#import <Ably/ARTLocalDevice.h>

@protocol ARTHTTPExecutor;

@class ARTRestChannels;
@class ARTClientOptions;
@class ARTAuth;
@class ARTPush;
@class ARTCancellable;
@class ARTStatsQuery;
@class ARTHTTPPaginatedResponse;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTRestProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Construct a RestClient object using an Ably [ClientOptions]{@link ClientOptions} object.
 *
 * @param options A [ClientOptions]{@link ClientOptions} object to configure the client connection to Ably.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Instance the Ably library with the given options.
 * :param options: see ``ARTClientOptions`` for options
 * END LEGACY DOCSTRING
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 * BEGIN CANONICAL DOCSTRING
 * Constructs a RestClient object using an Ably API key or token string.
 * @param keyOrTokenStr The Ably API key or token string used to validate the client.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Instance the Ably library using a key only. This is simply a convenience constructor for the simplest case of instancing the library with a key for basic authentication and no other options.
 * :param key; String key (obtained from application dashboard)
 * END LEGACY DOCSTRING
 */
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)tokenId;

- (void)time:(ARTDateTimeCallback)callback;

- (BOOL)request:(NSString *)method
           path:(NSString *)path
         params:(nullable NSStringDictionary *)params
           body:(nullable id)body
        headers:(nullable NSStringDictionary *)headers
       callback:(ARTHTTPPaginatedCallback)callback
          error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)stats:(ARTPaginatedStatsCallback)callback;

- (BOOL)stats:(nullable ARTStatsQuery *)query
     callback:(ARTPaginatedStatsCallback)callback
        error:(NSError *_Nullable *_Nullable)errorPtr;

#if TARGET_OS_IOS
@property (readonly) ARTLocalDevice *device;
#endif

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * A client that offers a simple stateless API to interact directly with Ably's REST API.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTRest object offers a simple stateless API to interact directly with Ably’s REST API.
 * END LEGACY DOCSTRING
 */
@interface ARTRest : NSObject <ARTRestProtocol>

@property (readonly) ARTRestChannels *channels;
@property (readonly) ARTPush *push;
/**
 * BEGIN CANONICAL DOCSTRING
 * An [Auth]{@link Auth} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTAuth *auth;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

@end

NS_ASSUME_NONNULL_END
