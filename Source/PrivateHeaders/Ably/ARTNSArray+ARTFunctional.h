#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (ARTFunctional)

- (NSArray *)artMap:(id (^)(id))f;
- (NSArray *)artFilter:(BOOL (^)(id))f;

@end

NS_ASSUME_NONNULL_END
