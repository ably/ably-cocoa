#import <Ably/ARTDefault.h>

@interface ARTDefault (Private)

+ (void)setConnectionStateTtl:(NSTimeInterval)value;
+ (void)setMaxMessageSize:(NSInteger)value;

+ (NSString *)connectivityCheckUrl;

@end
