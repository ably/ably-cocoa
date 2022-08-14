#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTLog;
@class ARTClientOptions;
@class ARTAuthOptions;
@class ARTTokenParams;
@class ARTTokenDetails;
@class ARTTokenRequest;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ARTAuth

@protocol ARTAuthProtocol

/**
 * BEGIN CANONICAL DOCSTRING
 * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error is raised if a `clientId` specified here conflicts with the `clientId` implicit in the token. Find out more about [identified clients](https://ably.com/docs/core-features/authentication#identified-clients).
 * END CANONICAL DOCSTRING
 */
@property (nullable, readonly) NSString *clientId;

@property (nullable, readonly) ARTTokenDetails *tokenDetails;

- (instancetype)init NS_UNAVAILABLE;

/**
 # (RSA8) Auth#requestToken
 
 Implicitly creates a `TokenRequest` if required, and requests a token from Ably if required.
 
 `TokenParams` and `AuthOptions` are optional.
 When provided, the values supersede matching client library configured params and options.
 
 - Parameter tokenParams: Token params (optional).
 - Parameter authOptions: Authentication options (optional).
 - Parameter callback: Completion callback (ARTTokenDetails, NSError).
 */
- (void)requestToken:(nullable ARTTokenParams *)tokenParams
         withOptions:(nullable ARTAuthOptions *)authOptions
            callback:(ARTTokenDetailsCallback)callback;

- (void)requestToken:(ARTTokenDetailsCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Instructs the library to get a new token immediately. When using the realtime client, it upgrades the current realtime connection to use the new token, or if not connected, initiates a connection to Ably, once the new token has been obtained. Also stores any [`TokenParams`]{@link TokenParams} and [`AuthOptions`]{@link AuthOptions} passed in as the new defaults, to be used for all subsequent implicit or explicit token requests. Any [`TokenParams`]{@link TokenParams} and [`AuthOptions`]{@link AuthOptions} objects passed in entirely replace, as opposed to being merged with, the current client library saved values.
 *
 * @param tokenParams A [`TokenParams`]{@link TokenParams} object.
 * @param authOptions An [`AuthOptions`]{@link AuthOptions} object.
 *
 * @return A [`TokenDetails`]{@link TokenDetails} object.
 * END CANONICAL DOCSTRING
 */
- (void)authorize:(nullable ARTTokenParams *)tokenParams
          options:(nullable ARTAuthOptions *)authOptions
         callback:(ARTTokenDetailsCallback)callback;

- (void)authorize:(ARTTokenDetailsCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates and signs an Ably [`TokenRequest`]{@link TokenRequest} based on the specified (or if none specified, the client library stored) [`TokenParams`]{@link TokenParams} and [`AuthOptions`]{@link AuthOptions}. Note this can only be used when the API `key` value is available locally. Otherwise, the Ably [`TokenRequest`]{@link TokenRequest} must be obtained from the key owner. Use this to generate an Ably [`TokenRequest`]{@link TokenRequest} in order to implement an Ably Token request callback for use by other clients. Both [`TokenParams`]{@link TokenParams} and [`AuthOptions`]{@link AuthOptions} are optional. When omitted or `null`, the default token parameters and authentication options for the client library are used, as specified in the [`ClientOptions`]{@link ClientOptions} when the client library was instantiated, or later updated with an explicit `authorize` request. Values passed in are used instead of, rather than being merged with, the default values. To understand why an Ably [`TokenRequest`]{@link TokenRequest} may be issued to clients in favor of a token, see [Token Authentication explained](https://ably.com/docs/core-features/authentication/#token-authentication).
 *
 * @param tokenParams A [`TokenParams`]{@link TokenParams} object.
 * @param options An [`AuthOptions`]{@link AuthOptions} object.
 *
 * @return A [`TokenRequest`]{@link TokenRequest} object.
 * END CANONICAL DOCSTRING
 */
- (void)createTokenRequest:(nullable ARTTokenParams *)tokenParams
                   options:(nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTTokenRequest *_Nullable tokenRequest, NSError *_Nullable error))callback;

- (void)createTokenRequest:(void (^)(ARTTokenRequest *_Nullable tokenRequest, NSError *_Nullable error))callback;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates Ably [`TokenRequest`]{@link TokenRequest} objects and obtains Ably Tokens from Ably to subsequently issue to less trusted clients.
 * END CANONICAL DOCSTRING
 */
@interface ARTAuth : NSObject <ARTAuthProtocol>

@end

NS_ASSUME_NONNULL_END
