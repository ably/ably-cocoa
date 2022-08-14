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

- (void)authorize:(nullable ARTTokenParams *)tokenParams
          options:(nullable ARTAuthOptions *)authOptions
         callback:(ARTTokenDetailsCallback)callback;

- (void)authorize:(ARTTokenDetailsCallback)callback;

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
