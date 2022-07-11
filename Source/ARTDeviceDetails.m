#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"

@implementation ARTDeviceDetails

- (instancetype)init {
    if (self = [super init]) {
        _metadata = [[NSDictionary alloc] init];
        _pushRecipient = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithId:(ARTDeviceId *)deviceId {
    if (self = [self init]) {
        _id = deviceId;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTDeviceDetails *device = [[[self class] allocWithZone:zone] init];

    device.id = [self.id copy];
    device.clientId = [self.clientId copy];
    device.platform = [self.platform copy];
    device.formFactor = [self.formFactor copy];
    device.metadata = [self.metadata copy];
    device.pushRecipient = [self.pushRecipient copy];

    return device;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t id: %@; \n\t clientId: %@; \n\t platform: %@; \n\t formFactor: %@;", [super description], self.id, self.clientId, self.formFactor, self.platform];
}

- (BOOL)isEqualToDeviceDetail:(ARTDeviceDetails *)device {
    if (!device) {
        return NO;
    }

    BOOL haveEqualDeviceId = (!self.id && !device.id) || [self.id isEqualToString:device.id];
    BOOL haveEqualClientId = (!self.clientId && !device.clientId) || [self.clientId isEqualToString:device.clientId];
    BOOL haveEqualPlatform = (!self.platform && !device.platform) || [self.platform isEqualToString:device.platform];
    BOOL haveEqualFormFactor = (!self.formFactor && !device.formFactor) || [self.formFactor isEqualToString:device.formFactor];

    return haveEqualDeviceId && haveEqualClientId && haveEqualPlatform && haveEqualFormFactor;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ARTDeviceDetails class]]) {
        return NO;
    }

    return [self isEqualToDeviceDetail:(ARTDeviceDetails *)object];
}

- (NSUInteger)hash {
    return [self.id hash] ^ [self.clientId hash] ^ [self.formFactor hash] ^ [self.platform hash];
}

@end
