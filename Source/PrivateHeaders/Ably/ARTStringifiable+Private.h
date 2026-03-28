#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTStringifiable ()

- (instancetype)initWithString:(NSString *)value;
- (instancetype)initWithNumber:(NSNumber *)value;
- (instancetype)initWithBool:(BOOL)value;

@end

NS_ASSUME_NONNULL_END
