@import Foundation;

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ARTArchive)
- (nullable NSData *)art_archiveWithLogger:(nullable ARTInternalLog *)logger;
+ (nullable id)art_unarchiveFromData:(NSData *)data withLogger:(nullable ARTInternalLog *)logger;
@end

NS_ASSUME_NONNULL_END
