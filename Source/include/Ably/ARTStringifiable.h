#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// :nodoc:
@interface ARTStringifiable : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@property(nonatomic, readonly) NSString* stringValue;

+ (ARTStringifiable*)withString:(NSString *)value;
+ (ARTStringifiable*)withNumber:(NSNumber *)value;
+ (ARTStringifiable*)withBool:(BOOL)value;

@end

NS_ASSUME_NONNULL_END
