#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTTokenParams.h>
#import <Ably/ARTAuthOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the properties of a request for a token to Ably. Tokens are generated using `-[ARTAuth requestToken:]`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTTokenRequest : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The name of the key against which this request is made. The key name is public, whereas the key secret is private.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly, copy) NSString *keyName;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The client ID to associate with the requested Ably Token. When provided, the Ably Token may only be used to perform operations on behalf of that client ID.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A cryptographically secure random string of at least 16 characters, used to ensure the `ARTTokenRequest` cannot be reused.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly, copy) NSString *nonce;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The Message Authentication Code for this request.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Valid HMAC is created using the key secret.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly, copy) NSString *mac;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Capability of the requested Ably Token. If the Ably `ARTTokenRequest` is successful, the capability of the returned Ably Token will be the intersection of this capability with the capability of the issuing key. The capabilities value is a JSON-encoded representation of the resource paths and associated operations. Read more about capabilities in the [capabilities docs](https://ably.com/docs/realtime/authentication).
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, copy, nullable) NSString *capability;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Requested time to live for the Ably Token in milliseconds. If the Ably `ARTTokenRequest` is successful, the TTL of the returned Ably Token is less than or equal to this value, depending on application settings and the attributes of the issuing key. The default is 60 minutes.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, nullable) NSNumber *ttl;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The timestamp of this request as `NSDate` object.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, strong) NSDate *timestamp;


- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A static factory method to create an `ARTTokenRequest` object from a deserialized `TokenRequest`-like object or a JSON stringified `ARTTokenRequest` object. This method is provided to minimize bugs as a result of differing types by platform for fields such as `timestamp` or `ttl`. For example, in Ruby `ttl` in the `TokenRequest` object is exposed in seconds as that is idiomatic for the language, yet when serialized to JSON using `to_json` it is automatically converted to the Ably standard which is milliseconds. By using the `fromJson()` method when constructing a `ARTTokenRequest` object, Ably ensures that all fields are consistently serialized and deserialized across platforms.
 *
 * @param json A deserialized `TokenRequest`-like object or a JSON stringified `TokenRequest` object to create an `ARTTokenRequest`.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return An Ably token request object.
 * END CANONICAL PROCESSED DOCSTRING
 */
+ (ARTTokenRequest *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)errorPtr;

@end

@interface ARTTokenRequest (ARTTokenDetailsCompatible) <ARTTokenDetailsCompatible>
@end

NS_ASSUME_NONNULL_END
