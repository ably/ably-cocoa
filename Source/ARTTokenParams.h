#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTClientOptions.h>

@class ARTTokenRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Defines the properties of an Ably Token.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTTokenParams is used in the parameters of token authentication requests, corresponding to the desired attributes of the Ably Token.
 * END LEGACY DOCSTRING
 */
@interface ARTTokenParams : NSObject<NSCopying>

/**
 Represents time to live (expiry) of this token as a NSTimeInterval.
 */
@property (nonatomic, strong, nullable) NSNumber *ttl;

/**
 * BEGIN CANONICAL DOCSTRING
 * The capabilities associated with this Ably Token. The capabilities value is a JSON-encoded representation of the resource paths and associated operations. Read more about capabilities in the [capabilities docs](https://ably.com/docs/core-features/authentication/#capabilities-explained).
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Contains the capability JSON stringified.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) NSString *capability;

/**
 * BEGIN CANONICAL DOCSTRING
 * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error is raised if a `clientId` specified here conflicts with the `clientId` implicit in the token. Find out more about [identified clients](https://ably.com/docs/core-features/authentication#identified-clients).
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * A clientId to associate with this token.
 * END LEGACY DOCSTRING
 */
@property (nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 */
@property (nullable, nonatomic, copy, readwrite) NSDate *timestamp;

/**
 * BEGIN CANONICAL DOCSTRING
 * A cryptographically secure random string of at least 16 characters, used to ensure the [`TokenRequest`]{@link TokenRequest} cannot be reused.
 * END CANONICAL DOCSTRING
 */
@property (nullable, nonatomic, readonly, strong) NSString *nonce;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId nonce:(NSString *_Nullable)nonce;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams;

- (NSMutableArray<NSURLQueryItem *> *)toArray;
- (NSArray<NSURLQueryItem *> *)toArrayWithUnion:(NSArray *)items;
- (NSStringDictionary *)toDictionaryWithUnion:(NSArray<NSURLQueryItem *> *)items;

@end

NS_ASSUME_NONNULL_END
