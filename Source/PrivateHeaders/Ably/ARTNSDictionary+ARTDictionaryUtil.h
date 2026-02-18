#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (ARTDictionaryUtil)

- (nullable NSString *)artString:(id)key;
- (nullable NSNumber *)artNumber:(id)key;
- (nullable NSDate *)artTimestamp:(id)key;
- (nullable NSArray *)artArray:(id)key;
- (nullable NSDictionary *)artDictionary:(id)key;
- (NSInteger)artInteger:(id)key;
- (BOOL)artBoolean:(id)key;

- (nullable id)artTyped:(Class)cls key:(id)key;

/**
 * Maps dictionary values using the provided block function.
 * @param f Block function that transforms each value
 * @return New dictionary with transformed values
 */
- (NSDictionary *)artMap:(id _Nullable (^)(id key, id value))f;

@end

NS_ASSUME_NONNULL_END
