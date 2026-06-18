#import <Ably/ARTDefault.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDefaultProduction;

@interface ARTDefault (Private)

+ (void)setConnectionStateTtl:(NSTimeInterval)value;
+ (void)setMaxMessageSize:(NSInteger)value;

+ (NSInteger)maxSandboxMessageSize;
+ (NSInteger)maxProductionMessageSize;

@end

NS_ASSUME_NONNULL_END
