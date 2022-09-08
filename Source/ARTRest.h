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

/**
 The protocol upon which the top level object `ARTRest` is implemented.
 */
@protocol ARTRestProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Construct an `ARTRest` object using an Ably `ARTClientOptions` object.
 *
 * @param options A `ARTClientOptions` object to configure the client connection to Ably.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Constructs a `ARTRest` object using an Ably API key.
 * @param key The Ably API key used to validate the client.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (instancetype)initWithKey:(NSString *)key;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Constructs a `ARTRest` object using an Ably token string.
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

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Makes a REST request to a provided path. This is provided as a convenience for developers who wish to use REST API functionality that is either not documented or is not yet included in the public API, without having to directly handle features such as authentication, paging, fallback hosts, MsgPack and JSON support.
 *
 * @param method The request method to use, such as GET, POST.
 * @param path The request path.
 * @param params The parameters to include in the URL query of the request. The parameters depend on the endpoint being queried. See the [REST API reference](https://ably.com/docs/api/rest-api) for the available parameters of each endpoint.
 * @param body The JSON body of the request.
 * @param headers Additional HTTP headers to include in the request.
 * @param callback A callback for retriving `ARTHttpPaginatedResponse` object returned by the HTTP request, containing an empty or JSON-encodable object.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.

 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
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
- (BOOL)stats:(nullable ARTStatsQuery *)query
     callback:(ARTPaginatedStatsCallback)callback
        error:(NSError *_Nullable *_Nullable)errorPtr;

#if TARGET_OS_IOS
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves an `ARTLocalDevice` object that represents the current state of the device as a target for push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTLocalDevice *device;
#endif

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A client that offers a simple stateless API to interact directly with Ably's REST API.
 * END CANONICAL DOCSTRING
 */
@interface ARTRest : NSObject <ARTRestProtocol>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTChannels` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTRestChannels *channels;
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

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

@end

NS_ASSUME_NONNULL_END
