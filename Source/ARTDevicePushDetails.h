#import <Ably/ARTTypes.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDevicePushDetails : NSObject

@property (nonatomic) ARTPushState state;
@property (nullable, nonatomic) ARTErrorInfo *errorReason;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *recipient;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
