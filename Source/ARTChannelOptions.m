#import "ARTChannelOptions.h"
#import "ARTChannelOptions+Private.h"
#import "ARTEncoder.h"

@implementation ARTChannelOptions {
    ARTCipherParams *_cipher;
}

- (instancetype)initWithCipher:(id<ARTCipherParamsCompatible>)cipherParams {
    if (self = [super init]) {
        self->_cipher = [cipherParams toCipherParams];
    }
    return self;
}

- (instancetype)initWithCipherKey:(id<ARTCipherKeyCompatible>)key {
    return [self initWithCipher:@{@"key": key}];
}

- (ARTCipherParams *)cipher {
    return _cipher;
}

- (void)setCipher:(ARTCipherParams *)cipher {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change options after you've passed it to receiver.", self.class]
                                     userInfo:nil];
    }
    _cipher = cipher;
}

@end
