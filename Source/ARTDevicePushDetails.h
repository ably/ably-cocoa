#import <Ably/ARTTypes.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDevicePushDetails : NSObject

@property (nonatomic) ARTPushState state;
@property (nullable, nonatomic) ARTErrorInfo *errorReason;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *recipient;

- (instancetype)init;

- (NSString *)stateString;

+ (ARTPushState)stateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
