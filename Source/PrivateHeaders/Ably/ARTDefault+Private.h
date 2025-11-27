#import <Ably/ARTDefault.h>

extern NSString *const ARTDefaultProductionEnvironment;

@interface ARTDefault (Private)

+ (void)setConnectionStateTtl:(NSTimeInterval)value;
+ (void)setMaxMessageSize:(NSInteger)value;

+ (NSInteger)maxSandboxMessageSize;
+ (NSInteger)maxProductionMessageSize;

+ (NSString *)connectivityCheckUrl;

@end
