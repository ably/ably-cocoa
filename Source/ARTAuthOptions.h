#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTAuth;
@class ARTTokenDetails;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTTokenDetailsCompatible <NSObject>
- (void)toTokenDetails:(ARTAuth *)auth callback:(ARTTokenDetailsCallback)callback;
@end

@interface NSString (ARTTokenDetailsCompatible) <ARTTokenDetailsCompatible>
@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Passes authentication-specific properties in authentication requests to Ably. Properties set using `AuthOptions` are used instead of the default values set when the client library is instantiated, as opposed to being merged with them.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTAuthOptions is used when making authentication requests. These options will supplement or override the corresponding options given when the library was instantiated.
 * END LEGACY DOCSTRING
 */
@interface ARTAuthOptions : NSObject<NSCopying>

/**
 * BEGIN CANONICAL DOCSTRING
 * The full API key string, as obtained from the [Ably dashboard](https://ably.com/dashboard). Use this option if you wish to use Basic authentication, or wish to be able to issue Ably Tokens without needing to defer to a separate entity to sign Ably [`TokenRequest`s]{@link TokenRequest}. Read more about [Basic authentication](https://ably.com/docs/core-features/authentication#basic-authentication).
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Full Ably key string as obtained from dashboard.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) NSString *key;

/**
 An authentication token issued for this application against a specific key and `TokenParams`.
 */
@property (nonatomic, copy, nullable) NSString *token;

/**
 An authentication token issued for this application against a specific key and `TokenParams`.
 */
@property (nonatomic, strong, nullable) ARTTokenDetails *tokenDetails;

/**
 * BEGIN CANONICAL DOCSTRING
 * Called when a new token is required. The role of the callback is to obtain a fresh token, one of: an Ably Token string (in plain text format); a signed [`TokenRequest`]{@link TokenRequest}; a [`TokenDetails`]{@link TokenDetails} (in JSON format); an [Ably JWT](https://ably.com/docs/core-features/authentication#ably-jwt). See [the authentication documentation](https://ably.com/docs/realtime/authentication) for details of the Ably [`TokenRequest`]{@link TokenRequest} format and associated API calls.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * A callback to call to obtain a signed token request. This enables a client to obtain token requests from another entity, so tokens can be renewed without the client requiring access to keys.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) ARTAuthCallback authCallback;

/**
 * BEGIN CANONICAL DOCSTRING
 * A URL that the library may use to obtain a token string (in plain text format), or a signed [`TokenRequest`]{@link TokenRequest} or [`TokenDetails`]{@link TokenDetails} (in JSON format) from.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * A URL to queryto obtain a signed token request. This enables a client to obtain token requests from another entity, so tokens can be renewed without the client requiring access to keys.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, strong, nullable) NSURL *authUrl;

/**
 * BEGIN CANONICAL DOCSTRING
 * The HTTP verb to use for any request made to the `authUrl`, either `GET` or `POST`. The default value is `GET`.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * The HTTP verb to be used when a request is made by the library to the authUrl. Defaults to GET, supports GET and POST.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, null_resettable) NSString *authMethod;

/**
 * BEGIN CANONICAL DOCSTRING
 * A set of key-value pair headers to be added to any request made to the `authUrl`. Useful when an application requires these to be added to validate the request or implement the response. If the `authHeaders` object contains an `authorization` key, then `withCredentials` is set on the XHR request.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Headers to be included in any request made by the library to the authURL.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) NSStringDictionary *authHeaders;

/**
 * BEGIN CANONICAL DOCSTRING
 * A set of key-value pair params to be added to any request made to the `authUrl`. When the `authMethod` is `GET`, query params are added to the URL, whereas when `authMethod` is `POST`, the params are sent as URL encoded form data. Useful when an application requires these to be added to validate the request or implement the response.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Additional params to be included in any request made by the library to the authUrl, either as query params in the case of GET or in the body in the case of POST.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) NSArray<NSURLQueryItem *> *authParams;

/**
 This may be set in instances that the library is to sign token requests based on a given key.
 If true, the library will query the Ably system for the current time instead of relying on a locally-available time of day.
 */
@property (nonatomic, assign, nonatomic) BOOL queryTime;

/**
 Forces authentication with token.
 */
@property (readwrite, assign, nonatomic) BOOL useTokenAuth;

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)token;
- (instancetype)initWithTokenDetails:(ARTTokenDetails *)tokenDetails;

- (NSString *)description;

- (ARTAuthOptions *)mergeWith:(ARTAuthOptions *)precedenceOptions;

- (BOOL)isMethodGET;
- (BOOL)isMethodPOST;

@end

NS_ASSUME_NONNULL_END
