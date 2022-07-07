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
 The ARTCipherParams object contains properties to configure encryption for a channel.
 */
@interface ARTCipherParams : NSObject <ARTCipherParamsCompatible>

/// The algorithm to use for encryption. Only AES is supported.
@property (readonly, strong, nonatomic) NSString *algorithm;

/// The private key used to encrypt and decrypt payloads.
@property (readonly, strong, nonatomic) NSData *key;

/// The length of the key in bits; for example 128 or 256.
@property (readonly, nonatomic) NSUInteger keyLength;

/// The cipher mode. Only CBC is supported.
@property (readonly, getter=getMode) NSString *mode;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key;

- (ARTCipherParams *)toCipherParams;

@end

/**
 The ARTCrypto object ensures that message payloads are encrypted, can never be decrypted by Ably, and can only be decrypted by other clients that share the same secret symmetric key.
 */
@interface ARTCrypto : NSObject

/**
 Retrieves, or optionally sets, the `ARTCipherParams` for the channel.
 @param params Overrides the default parameters. A suitable key must be provided as a minimum.
 @return An `ARTCipherParams` object, using the default values for any field not supplied.
 */
+ (ARTCipherParams *)getDefaultParams:(NSDictionary *)params;

/**
 Generates a random key to be used in the encryption of the channel.
 @param keyLength The length of the key, in bits, to be generated.
 @return `NSData` The key as a binary data.
 */
+ (NSData *)generateRandomKey:(NSUInteger)keyLength;

/**
 Same as `+generateRandomKey:`, but with the default key length of the default algorithm: for AES this is 256 bits.
 @return `NSData` The key as a binary data.
 */
+ (NSData *)generateRandomKey;

@end

NS_ASSUME_NONNULL_END
