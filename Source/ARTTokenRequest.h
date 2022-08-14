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
 Identifier for the key (public).
 */
@property (nonatomic, readonly, copy) NSString *keyName;

/**
 A clientId to associate with this token.
 */
@property (nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 Unique 16+ character nonce.
 */
@property (nonatomic, readonly, copy) NSString *nonce;

/**
 Valid HMAC is created using the key secret.
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
 Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
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
