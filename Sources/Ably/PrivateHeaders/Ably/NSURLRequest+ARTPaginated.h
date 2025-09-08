#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (ARTPaginated)

+ (nullable NSURLRequest *)requestWithPath:(NSString *)path relativeTo:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
