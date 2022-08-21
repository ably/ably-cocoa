#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables `vcdiff` encoded messages to be decoded.
 * END CANONICAL DOCSTRING
 */
@protocol ARTVCDiffDecoder
- (nullable NSData *)decode:(NSData *)delta base:(NSData *)base error:(NSError *__autoreleasing _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
