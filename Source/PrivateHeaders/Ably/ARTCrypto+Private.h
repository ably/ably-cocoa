#import <Ably/ARTCrypto.h>

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTCipherParams ()

@property (readonly, nonatomic, nullable) NSData *iv;
@property (nonatomic) ARTInternalLog *logger;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key iv:(NSData *_Nullable)iv;

@end

@protocol ARTChannelCipher

- (ARTStatus *)encrypt:(NSData *)plaintext output:(NSData *_Nullable *_Nullable)output;
- (ARTStatus *)decrypt:(NSData *)ciphertext output:(NSData *_Nullable *_Nullable)output;
- (nullable NSString *)cipherName;
- (size_t) keyLength;

@end

@interface ARTCbcCipher : NSObject<ARTChannelCipher>

- (id)initWithCipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)cbcCipherWithParams:(ARTCipherParams *)cipherParams;


@property (nonatomic) ARTInternalLog *logger;
@property (readonly, nonatomic) NSData *keySpec;
@property NSData *iv;
@property (readonly) NSUInteger blockLength;

@end

@interface ARTCrypto ()

+ (NSString *)defaultAlgorithm;
+ (int)defaultKeyLength;
+ (int)defaultBlockLength;

+ (nullable NSMutableData *)generateSecureRandomData:(size_t)length;
+ (NSData *)generateHashSHA256:(NSData *)data;

+ (id<ARTChannelCipher>)cipherWithParams:(ARTCipherParams *)params;

@end

NS_ASSUME_NONNULL_END
