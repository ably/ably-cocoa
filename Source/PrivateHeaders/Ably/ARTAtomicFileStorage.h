#import <Foundation/Foundation.h>

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

/// Reads and writes a single property-list-backed file atomically. On iOS the
/// file is written with `NSFileProtectionNone` so the data is readable even
/// before the user has unlocked the device after a reboot.
///
/// This class is thread-safe.
@interface ARTAtomicFileStorage : NSObject

- (instancetype)initWithFileURL:(NSURL *)fileURL logger:(nullable ARTInternalLog *)logger;

@property (nonatomic, readonly) NSURL *fileURL;

/// Returns the persisted dictionary. Returns an empty dictionary if the file
/// does not exist or cannot be parsed.
- (NSDictionary<NSString *, id> *)load;

/// Writes `dictionary` to the file. The write is atomic at the file-system
/// level (write-to-temp-and-rename). Returns `YES` on success.
- (BOOL)save:(NSDictionary<NSString *, id> *)dictionary error:(NSError * _Nullable * _Nullable)error;

- (BOOL)fileExists;

/// Returns `YES` if the file existed before the call.
- (BOOL)removeFile;

@end

NS_ASSUME_NONNULL_END
