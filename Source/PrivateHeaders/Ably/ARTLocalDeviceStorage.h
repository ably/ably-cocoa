#import <Foundation/Foundation.h>
#import "ARTDeviceStorage.h"

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

/// Marker written into the persisted file when its contents were migrated from
/// the legacy `NSUserDefaults`/keychain layout.
/// It exists so that, if we later need to deal with legacy out-of-sync issues
/// (e.g. a `deviceIdentityToken` that doesn't match the migrated `deviceId`),
/// we can identify migrated data and decide whether to validate it.
extern NSString *const ARTMigratedFromLegacyStorageKey;

/// Block used during legacy migration to look up the device secret in the
/// keychain. The real implementation calls `SecItemCopyMatching`; tests
/// substitute a stub that returns the desired `OSStatus` so that the
/// migration's keychain-locked / unreachable branches can be exercised.
typedef NSString * _Nullable (^ARTLegacyKeychainSecretReader)(NSString *deviceId, OSStatus * _Nullable outStatus);

/// Persists `LocalDevice` data and push-activation-state-machine data to a
/// single always-available file in the app's Application Support directory.
///
/// Writes are atomic: every persisted value lives in the same file and is
/// written with a write-to-temp-and-rename, so it is impossible for, e.g., a
/// `deviceIdentityToken` to be paired with a `deviceId` that it does not
/// belong to.
///
/// On first init, data persisted by older SDK versions (in `NSUserDefaults`
/// and the keychain) is migrated into the new file (old entries are preserved just in case).
@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

- (instancetype)initWithLogger:(nullable ARTInternalLog *)logger logValues:(BOOL)logValues;

+ (instancetype)newWithLogger:(nullable ARTInternalLog *)logger logValues:(BOOL)logValues;

/// Initialiser for tests. `baseDirectoryURL` is the directory in which the
/// storage file lives (and into which legacy data is migrated).
- (instancetype)initWithBaseDirectoryURL:(NSURL *)baseDirectoryURL
                                  logger:(nullable ARTInternalLog *)logger
                               logValues:(BOOL)logValues;

/// Designated initialiser. `legacyKeychainReader` overrides how the migration
/// reads the legacy device secret from the keychain; pass `nil` to use the
/// real `SecItemCopyMatching` implementation.
- (instancetype)initWithBaseDirectoryURL:(NSURL *)baseDirectoryURL
                                  logger:(nullable ARTInternalLog *)logger
                               logValues:(BOOL)logValues
                    legacyKeychainReader:(nullable ARTLegacyKeychainSecretReader)legacyKeychainReader NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Returns the directory used by `+newWithLogger:logValues:`.
+ (NSURL *)defaultBaseDirectoryURL;

@end

NS_ASSUME_NONNULL_END
