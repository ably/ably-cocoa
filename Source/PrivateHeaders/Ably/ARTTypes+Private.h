@import Foundation;

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ARTArchive)
- (nullable NSData *)art_archiveWithLogger:(nullable ARTLog *)logger;
+ (nullable id)art_unarchiveFromData:(NSData *)data withLogger:(nullable ARTLog *)logger;
@end

NS_ASSUME_NONNULL_END
