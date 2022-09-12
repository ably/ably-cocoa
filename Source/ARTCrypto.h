#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@protocol ARTCipherKeyCompatible <NSObject>
- (NSData *)toData;
@end

/// :nodoc:
@interface NSString (ARTCipherKeyCompatible) <ARTCipherKeyCompatible>
- (NSData *)toData;
@end

/// :nodoc:
@interface NSData (ARTCipherKeyCompatible) <ARTCipherKeyCompatible>
- (NSData *)toData;
@end

@class ARTCipherParams;

/// :nodoc:
@protocol ARTCipherParamsCompatible <NSObject>
- (ARTCipherParams *)toCipherParams;
@end

/// :nodoc:
@interface NSDictionary (ARTCipherParamsCompatible) <ARTCipherParamsCompatible>
- (ARTCipherParams *)toCipherParams;
@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Sets the properties to configure encryption for an `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTCipherParams : NSObject <ARTCipherParamsCompatible>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The algorithm to use for encryption. Only `AES` is supported and is the default value.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) NSString *algorithm;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The private key used to encrypt and decrypt payloads.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) NSData *key;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The length of the key in bits; for example 128 or 256.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSUInteger keyLength;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The cipher mode. Only `CBC` is supported and is the default value.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, getter=getMode) NSString *mode;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key;

/// :nodoc:
- (ARTCipherParams *)toCipherParams;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the properties required to configure the encryption of `ARTMessage` payloads.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTCrypto : NSObject
/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Returns an `ARTCipherParams` object, using the default values for any fields not supplied by the `ARTCipherParamOptions` object.
 *
 * @param values An `ARTCipherParams`-like dictionary object.
 *
 * @return An `ARTCipherParams` object, using the default values for any fields not supplied.
 * END CANONICAL PROCESSED DOCSTRING
 */
+ (ARTCipherParams *)getDefaultParams:(NSDictionary *)values;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Generates a random key to be used in the encryption of the channel.
 *
 * @param length The length of the key, in bits, to be generated.
 *
 * @return The key as a binary `NSData`.
 * END CANONICAL PROCESSED DOCSTRING
 */
+ (NSData *)generateRandomKey:(NSUInteger)length;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Generates a random key to be used in the encryption of the channel.
 * Here the default key length of the default algorithm is used: for `AES` this is 256 bits.
 *
 * @return The key as a binary `NSData`.
 * END CANONICAL PROCESSED DOCSTRING
 */
+ (NSData *)generateRandomKey;

@end

NS_ASSUME_NONNULL_END
