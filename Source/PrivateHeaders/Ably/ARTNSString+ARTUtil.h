#import <Foundation/Foundation.h>

#define NSStringFromBOOL(aBOOL) ((aBOOL) ? @"YES" : @"NO")

NS_ASSUME_NONNULL_BEGIN

@interface NSString (ARTUtil)

+ (NSString *)nilToEmpty:(nullable NSString *)aString;
- (BOOL)isEmptyString;
- (BOOL)isNotEmptyString;

@end

NS_ASSUME_NONNULL_END
