#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTTokenParams.h>
#import <Ably/ARTAuthOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the properties of a request for a token to Ably. Tokens are generated using [`requestToken`]{@link Auth#requestToken}.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTTokenRequest is a type containing parameters for an Ably token request. Ably tokens are requested using ``ARTAuth/requestToken``.
 * END LEGACY DOCSTRING
 */
@interface ARTTokenRequest : NSObject

/**
 * BEGIN CANONICAL DOCSTRING
 * The name of the key against which this request is made. The key name is public, whereas the key secret is private.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Identifier for the key (public).
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly, copy) NSString *keyName;

/**
 * BEGIN CANONICAL DOCSTRING
 * The client ID to associate with the requested Ably Token. When provided, the Ably Token may only be used to perform operations on behalf of that client ID.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * A clientId to associate with this token.
 * END LEGACY DOCSTRING
 */
@property (nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 * BEGIN CANONICAL DOCSTRING
 * A cryptographically secure random string of at least 16 characters, used to ensure the `TokenRequest` cannot be reused.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Unique 16+ character nonce.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly, copy) NSString *nonce;

/**
 * BEGIN CANONICAL DOCSTRING
 * The Message Authentication Code for this request.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Valid HMAC is created using the key secret.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly, copy) NSString *mac;

/**
 * BEGIN CANONICAL DOCSTRING
 * Capability of the requested Ably Token. If the Ably `TokenRequest` is successful, the capability of the returned Ably Token will be the intersection of this capability with the capability of the issuing key. The capabilities value is a JSON-encoded representation of the resource paths and associated operations. Read more about capabilities in the [capabilities docs](https://ably.com/docs/realtime/authentication).
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Contains the capability JSON stringified.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) NSString *capability;

/**
 Represents time to live (expiry) of this token as a NSTimeInterval.
 */
@property (nonatomic, strong, nullable) NSNumber *ttl;

/**
 * BEGIN CANONICAL DOCSTRING
 * The timestamp of this request as milliseconds since the Unix epoch.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, strong) NSDate *timestamp;


- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

/**
 * BEGIN CANONICAL DOCSTRING
 * A static factory method to create a `TokenRequest` object from a deserialized `TokenRequest`-like object or a JSON stringified `TokenRequest` object. This method is provided to minimize bugs as a result of differing types by platform for fields such as `timestamp` or `ttl`. For example, in Ruby `ttl` in the `TokenRequest` object is exposed in seconds as that is idiomatic for the language, yet when serialized to JSON using `to_json` it is automatically converted to the Ably standard which is milliseconds. By using the `fromJson()` method when constructing a `TokenRequest` object, Ably ensures that all fields are consistently serialized and deserialized across platforms.
 *
 * @param json A deserialized `TokenRequest`-like object or a JSON stringified `TokenRequest` object to create a `TokenRequest`.
 *
 * @return An Ably token request object.
 * END CANONICAL DOCSTRING
 */
+ (ARTTokenRequest *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)error;

@end

@interface ARTTokenRequest (ARTTokenDetailsCompatible) <ARTTokenDetailsCompatible>
@end

NS_ASSUME_NONNULL_END
