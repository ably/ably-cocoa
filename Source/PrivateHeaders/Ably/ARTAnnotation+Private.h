@import Foundation;
#import <Ably/ARTAnnotation.h>
#import "ARTDataEncoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTAnnotation ()

@property (nonatomic, readonly) BOOL isIdEmpty;

- (id)decodeDataWithEncoder:(ARTDataEncoder *)encoder error:(NSError *__nullable*__nullable)error;
- (id)encodeDataWithEncoder:(ARTDataEncoder *)encoder error:(NSError *__nullable*__nullable)error;

- (NSInteger)annotationSize;

/**
 * Internal initializer for converting outbound annotations to annotations before publishing
 */
- (instancetype)initWithId:(nullable NSString *)annotationId
                    action:(ARTAnnotationAction)action
                  clientId:(nullable NSString *)clientId
                      name:(nullable NSString *)name
                     count:(nullable NSNumber *)count
                      data:(nullable id)data
             messageSerial:(NSString *)messageSerial
                      type:(NSString *)type
                    extras:(nullable id<ARTJsonCompatible>)extras;

@end

NS_ASSUME_NONNULL_END
