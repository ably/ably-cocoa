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

/// The cipher mode. Only "CBC" is supported.
@property (readonly, getter=getMode) NSString *mode;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key;

- (ARTCipherParams *)toCipherParams;

@end

@interface ARTCrypto : NSObject

+ (ARTCipherParams *)getDefaultParams:(NSDictionary *)values;
+ (NSData *)generateRandomKey;
+ (NSData *)generateRandomKey:(NSUInteger)length;

@end

NS_ASSUME_NONNULL_END
