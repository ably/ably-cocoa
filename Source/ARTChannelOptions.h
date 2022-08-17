#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTCrypto.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Passes additional properties to a [`RestChannel`]{@link RestChannel} or [`RealtimeChannel`]{@link RealtimeChannel} object, such as encryption, [`ChannelMode`]{@link ChannelMode} and channel parameters.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTChannelOptions are used for setting channel parameters and configuring encryption.
 * END LEGACY DOCSTRING
 */
@interface ARTChannelOptions : NSObject

@property (nonatomic, strong, nullable) ARTCipherParams *cipher;

- (instancetype)initWithCipher:(id<ARTCipherParamsCompatible> _Nullable)cipherParams;
- (instancetype)initWithCipherKey:(id<ARTCipherKeyCompatible>)key;

@end

NS_ASSUME_NONNULL_END
