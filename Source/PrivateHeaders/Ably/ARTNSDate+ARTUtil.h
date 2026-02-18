#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (ARTUtil)

+ (instancetype)artDateFromNumberMs:(NSNumber *)number;
+ (instancetype)artDateFromIntegerMs:(long long)ms;

- (NSNumber *)artToNumberMs;
- (NSInteger)artToIntegerMs;

@end

NS_ASSUME_NONNULL_END
