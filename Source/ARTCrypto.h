#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTCipherKeyCompatible <NSObject>
- (NSData *)toData;
@end

@interface NSString (ARTCipherKeyCompatible) <ARTCipherKeyCompatible>
- (NSData *)toData;
@end

@interface NSData (ARTCipherKeyCompatible) <ARTCipherKeyCompatible>
- (NSData *)toData;
@end

@class ARTCipherParams;

@protocol ARTCipherParamsCompatible <NSObject>
- (ARTCipherParams *)toCipherParams;
@end

@interface NSDictionary (ARTCipherParamsCompatible) <ARTCipherParamsCompatible>
- (ARTCipherParams *)toCipherParams;
@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Sets the properties to configure encryption for an `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * ARTCipherParams contains configuration options for a channel cipher, including algorithm, mode, key length and key. Ably client libraries currently support AES with CBC, PKCS#7 with a default key length of 256 bits. All implementations also support AES128.
 * END LEGACY DOCSTRING
 */
@interface ARTCipherParams : NSObject <ARTCipherParamsCompatible>

/**
 * BEGIN CANONICAL DOCSTRING
 * The algorithm to use for encryption. Only `AES` is supported and is the default value.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) NSString *algorithm;

/**
 * BEGIN CANONICAL DOCSTRING
 * The private key used to encrypt and decrypt payloads.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) NSData *key;

/**
 * BEGIN CANONICAL DOCSTRING
 * The length of the key in bits; for example 128 or 256.
 * END CANONICAL DOCSTRING
 */
@property (readonly, nonatomic) NSUInteger keyLength;

/**
 * BEGIN CANONICAL DOCSTRING
 * The cipher mode. Only `CBC` is supported and is the default value.
 * END CANONICAL DOCSTRING
 */
@property (readonly, getter=getMode) NSString *mode;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key;

- (ARTCipherParams *)toCipherParams;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the properties required to configure the encryption of `ARTMessage` payloads.
 * END CANONICAL DOCSTRING
 */
@interface ARTCrypto : NSObject
/**
 * BEGIN CANONICAL DOCSTRING
 * Returns an `ARTCipherParams` object, using the default values for any fields not supplied by the `ARTCipherParamOptions` object.
 *
 * @param values An `ARTCipherParams`-like dictionary object.
 *
 * @return An `ARTCipherParams` object, using the default values for any fields not supplied.
 * END CANONICAL DOCSTRING
 */
+ (ARTCipherParams *)getDefaultParams:(NSDictionary *)values;

/**
 * BEGIN CANONICAL DOCSTRING
 * Generates a random key to be used in the encryption of the channel.
 *
 * @param length The length of the key, in bits, to be generated.
 *
 * @return The key as a binary `NSData`.
 * END CANONICAL DOCSTRING
 */
+ (NSData *)generateRandomKey:(NSUInteger)length;

/**
 * BEGIN CANONICAL DOCSTRING
 * Generates a random key to be used in the encryption of the channel.
 * Here the default key length of the default algorithm is used: for `AES` this is 256 bits.
 *
 * @return The key as a binary `NSData`.
 * END CANONICAL DOCSTRING
 */
+ (NSData *)generateRandomKey;

@end

NS_ASSUME_NONNULL_END
