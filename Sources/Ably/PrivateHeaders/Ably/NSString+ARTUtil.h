#import <Foundation/Foundation.h>

extern NSString *ARTStringFromBool(BOOL aBool);

@interface NSString (ARTUtil)

+ (NSString *)nilToEmpty:(NSString*)aString;
- (BOOL)isEmptyString;
- (BOOL)isNotEmptyString;

@end
