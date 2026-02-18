@import Foundation;
#import <Ably/ARTBaseMessage.h>
#import "ARTDataEncoder.h"
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage ()

@property (nonatomic, readonly) BOOL isIdEmpty;

- (id)decodeWithEncoder:(ARTDataEncoder *)encoder error:(NSError *_Nullable *_Nullable)error;
- (id)encodeWithEncoder:(ARTDataEncoder *)encoder error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
