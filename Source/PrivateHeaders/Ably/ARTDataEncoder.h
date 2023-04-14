#import <Foundation/Foundation.h>

#import <Ably/ARTStatus.h>
#import <Ably/ARTCrypto.h>

@class ARTCipherParams;
@class ARTPlugin;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@interface ARTDataEncoderOutput : NSObject

@property (readonly, nonatomic, nullable) id data;
@property (readonly, nonatomic, nullable) NSString *encoding;
@property (readonly, nonatomic, nullable) ARTErrorInfo *errorInfo;

- initWithData:(id _Nullable)data encoding:(NSString *_Nullable)encoding errorInfo:(ARTErrorInfo *_Nullable)errorInfo;

@end

/// :nodoc:
@interface ARTDataEncoder : NSObject

- (instancetype)initWithCipherParams:(ARTCipherParams *_Nullable)params logger:(ARTInternalLog *)logger error:(NSError *_Nullable*_Nullable)error;
- (ARTDataEncoderOutput *)encode:(id _Nullable)data;
- (ARTDataEncoderOutput *)decode:(id _Nullable)data encoding:(NSString *_Nullable)encoding;
- (ARTDataEncoderOutput *)decode:(id _Nullable)data identifier:(NSString *)identifier encoding:(NSString *_Nullable)encoding;

@end

/// :nodoc:
@interface NSString (ARTDataEncoder)

+ (NSString *)artAddEncoding:(NSString *)encoding toString:(NSString *_Nullable)s;
- (NSString *)artLastEncoding;
- (nullable NSString *)artRemoveLastEncoding;

@end

NS_ASSUME_NONNULL_END
