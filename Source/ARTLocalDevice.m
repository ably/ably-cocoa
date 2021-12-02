#import "ARTLocalDevice+Private.h"
#import "ARTDevicePushDetails.h"
#import "ARTPush.h"
#import "ARTEncoder.h"
#import "ARTLocalDeviceStorage.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTCrypto+Private.h"
#import "ARTAuth+Private.h"

NSString *const ARTDevicePlatform = @"ios";

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
NSString *const ARTDeviceFormFactor = @"phone";
#elif TARGET_OS_TV
NSString *const ARTDeviceFormFactor = @"tv";
#elif TARGET_OS_WATCH
NSString *const ARTDeviceFormFactor = @"watch";
#elif TARGET_OS_SIMULATOR
NSString *const ARTDeviceFormFactor = @"simulator";
#elif TARGET_OS_MAC
NSString *const ARTDeviceFormFactor = @"desktop";
#else
NSString *const ARTDeviceFormFactor = @"embedded";
#endif

NSString *const ARTDevicePushTransportType = @"apns";

@implementation ARTLocalDevice

static ARTLocalDevice *_shared;

+ (dispatch_queue_t)queue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.ably.device-storage", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (ARTLocalDevice *)shared {
    __block ARTLocalDevice *device;
    dispatch_sync(self.queue, ^{
        device = _shared;
    });
    return device;
}

+ (ARTLocalDevice *)shared_nosync {
    return _shared;
}

- (instancetype)initWithClientId:(NSString *)clientId logger:(ARTLog *)logger {
    if (self = [super init]) {
        self.clientId = clientId;
        _storage = [ARTLocalDeviceStorage newWithLogger:logger];
    }
    return self;
}

+ (ARTLocalDevice *)deviceWithClientId:(NSString *)clientId apnsToken:(NSString *)apnsToken logger:(ARTLog *)logger {
    ARTLocalDevice *device = [[ARTLocalDevice alloc] initWithClientId:clientId logger:logger];
    device.platform = ARTDevicePlatform;
    #if TARGET_OS_IOS
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomPad:
            device.formFactor = @"tablet";
        case UIUserInterfaceIdiomCarPlay:
            device.formFactor = @"car";
        default:
            device.formFactor = ARTDeviceFormFactor;
    }
    #else
    device.formFactor = ARTDeviceFormFactor;
    #endif
    device.push.recipient[@"transportType"] = ARTDevicePushTransportType;

    NSString *deviceId = [device.storage objectForKey:ARTDeviceIdKey];
    NSString *deviceSecret = deviceId == nil ? nil : [device.storage secretForDevice:deviceId];
    
    if (deviceId == nil || deviceSecret == nil) { // generate both at the same time
        deviceId = [self generateId];
        deviceSecret = [self generateSecret];
        
        [device.storage setObject:deviceId forKey:ARTDeviceIdKey];
        [device.storage setSecret:deviceSecret forDevice:deviceId];
    }
    
    device.id = deviceId;
    device.secret = deviceSecret;

    id detailsInfo = [device.storage objectForKey:ARTDeviceIdentityTokenKey];
    ARTDeviceIdentityTokenDetails *identityTokenDetails = detailsInfo != nil ? [ARTDeviceIdentityTokenDetails unarchive:detailsInfo] : nil;
    device->_identityTokenDetails = identityTokenDetails;

    [device setAndPersistAPNSDeviceToken:apnsToken];

    return device;
}

+ (ARTLocalDevice *)createDeviceWithClientId:(NSString *)clientId apnsToken:(NSString *)apnsToken logger:(ARTLog *)logger {
    // The device is shared in a static variable because it's a reflection
    // of what's persisted. Having a device instance per ARTRest instance
    // could leave some instances in a stale state, if, through another
    // instance, the persisted state is changed.
    //
    // As a side effect, the first instance "wins" at setting the device's
    // client ID and APNS token.
    __block ARTLocalDevice *device;
    dispatch_sync(self.queue, ^{
        if (_shared == nil) {
            _shared = [self deviceWithClientId:clientId apnsToken:apnsToken logger:logger];
        }
        device = _shared;
    });
    return device;
}

+ (ARTLocalDevice *)renewDeviceWithClientId:(NSString *)clientId logger:(ARTLog *)logger {
    __block ARTLocalDevice *device;
    dispatch_sync(self.queue, ^{
        NSString* apnsToken = [_shared.storage objectForKey:ARTAPNSDeviceTokenKey];
        NSAssert(apnsToken, @"APNS token not found.");
        _shared = [self deviceWithClientId:clientId apnsToken:apnsToken logger:logger];
        device = _shared;
    });
    return device;
}

+ (void)resetSharedDevice {
    _shared = nil;
}

+ (NSString *)generateId {
    return [NSUUID new].UUIDString;
}

+ (NSString *)generateSecret {
    NSData *randomData = [ARTCrypto generateSecureRandomData:32];
    NSData *hash = [ARTCrypto generateHashSHA256:randomData];
    return [hash base64EncodedStringWithOptions:0];
}

- (NSString *)apnsDeviceToken {
    return self.push.recipient[@"deviceToken"];
}

- (void)setAndPersistAPNSDeviceToken:(NSString *)token {
    self.push.recipient[@"deviceToken"] = token;
    [self.storage setObject:token forKey:ARTAPNSDeviceTokenKey];
}

- (void)setAndPersistIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)tokenDetails {
    [self.storage setObject:[tokenDetails archive] forKey:ARTDeviceIdentityTokenKey];
    _identityTokenDetails = tokenDetails;
    if (self.clientId == nil) {
        self.clientId = tokenDetails.clientId;
    }
}

- (BOOL)isRegistered {
    return _identityTokenDetails != nil;
}

- (void)clearStorage {
    for (NSString *key in @[ ARTDeviceIdKey, ARTDeviceIdentityTokenKey ]) {
        [self.storage setObject:nil forKey:key];
    }
}

- (void)reset {
    dispatch_sync([ARTLocalDevice queue], ^{
        self.id = nil;
        self.secret = nil;
        self.clientId = nil;
        _identityTokenDetails = nil;
        [self.push.recipient removeAllObjects];
        [self clearStorage];
    });
}

@end
