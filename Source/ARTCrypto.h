//
//  ARTCrypto.h
//
//

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

@interface ARTCipherParams : NSObject <ARTCipherParamsCompatible>
@property (readonly, strong, nonatomic) NSString *algorithm;
@property (readonly, strong, nonatomic) NSData *key;
@property (readonly, nonatomic) NSUInteger keyLength;
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
