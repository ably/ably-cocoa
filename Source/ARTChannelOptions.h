#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTCrypto.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Passes additional properties to an `ARTRestChannel` or an `ARTRealtimeChannel` object, such as encryption, an `ARTChannelMode` and channel parameters.
 * END CANONICAL DOCSTRING
 */
@interface ARTChannelOptions : NSObject

/**
 * BEGIN CANONICAL DOCSTRING
 * Requests encryption for this channel when not `nil`, and specifies encryption-related parameters (such as algorithm, chaining mode, key length and key). See [an example](https://ably.com/docs/realtime/encryption#getting-started).
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, strong, nullable) ARTCipherParams *cipher;

- (instancetype)initWithCipher:(id<ARTCipherParamsCompatible> _Nullable)cipherParams;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates an options object using a key only.
 *
 * @param key A private key used to encrypt and decrypt payloads.
 *
 * @return An `ARTChannelOptions` object.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithCipherKey:(id<ARTCipherKeyCompatible>)key;

@end

NS_ASSUME_NONNULL_END
