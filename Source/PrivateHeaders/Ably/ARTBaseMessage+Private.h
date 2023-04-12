@import Foundation;
#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTDataEncoder.h>
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage ()

@property (nonatomic, readonly) BOOL isIdEmpty;

- (id __nonnull)decodeWithEncoder:(ARTDataEncoder*)encoder error:(NSError *__nullable*__nullable)error;
- (id __nonnull)encodeWithEncoder:(ARTDataEncoder*)encoder error:(NSError *__nullable*__nullable)error;

@end

NS_ASSUME_NONNULL_END
