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

/**
 * BEGIN CANONICAL DOCSTRING
 * Makes a REST request to a provided path. This is provided as a convenience for developers who wish to use REST API functionality that is either not documented or is not yet included in the public API, without having to directly handle features such as authentication, paging, fallback hosts, MsgPack and JSON support.
 *
 * @param method The request method to use, such as GET, POST.
 * @param path The request path.
 * @param params The parameters to include in the URL query of the request. The parameters depend on the endpoint being queried. See the [REST API reference](https://ably.com/docs/api/rest-api) for the available parameters of each endpoint.
 * @param body The JSON body of the request.
 * @param headers Additional HTTP headers to include in the request.
 * @return An [HttpPaginatedResponse]{@link HttpPaginatedResponse} object returned by the HTTP request, containing an empty or JSON-encodable object.
 * END CANONICAL DOCSTRING
 */
- (BOOL)request:(NSString *)method
           path:(NSString *)path
         params:(nullable NSStringDictionary *)params
           body:(nullable id)body
        headers:(nullable NSStringDictionary *)headers
       callback:(ARTHTTPPaginatedCallback)callback
          error:(NSError *_Nullable *_Nullable)errorPtr;

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
- (BOOL)stats:(nullable ARTStatsQuery *)query
     callback:(ARTPaginatedStatsCallback)callback
        error:(NSError *_Nullable *_Nullable)errorPtr;

#if TARGET_OS_IOS
/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a [LocalDevice]{@link LocalDevice} object that represents the current state of the device as a target for push notifications.
 *
 * @return A [LocalDevice]{@link LocalDevice} object.
 * END CANONICAL DOCSTRING
 */
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

/**
 * BEGIN CANONICAL DOCSTRING
 * A [Channels]{@link Channels} object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRestChannels *channels;
/**
 * BEGIN CANONICAL DOCSTRING
 * A [Push]{@link Push} object.
 * END CANONICAL DOCSTRING
 */
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
