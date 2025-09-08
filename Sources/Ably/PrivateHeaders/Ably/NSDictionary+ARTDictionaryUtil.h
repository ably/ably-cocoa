#import <Foundation/Foundation.h>

@interface NSDictionary (ARTDictionaryUtil)

- (NSString *)artString:(id)key;
- (NSNumber *)artNumber:(id)key;
- (NSDate *)artTimestamp:(id)key;
- (NSArray *)artArray:(id)key;
- (NSDictionary *)artDictionary:(id)key;
- (NSInteger)artInteger:(id)key;
- (BOOL)artBoolean:(id)key;

- (id)artTyped:(Class)cls key:(id)key;

/**
 Creates NSURLQueryItem for given value, and key, and returns a new dictionary with the item added.
 */
- (NSDictionary *)addingValueAsURLQueryItem:(NSString *)value forKey:(NSString *)key;

@end
