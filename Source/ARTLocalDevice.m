#import "ARTLocalDevice+Private.h"
#import "ARTDeviceDetails+Private.h"
#import "ARTDevicePushDetails.h"
#import "ARTPush.h"
#import "ARTEncoder.h"
#import "ARTDeviceStorage.h"
#import "ARTDeviceIdentityTokenDetails+Private.h"
#import "ARTCrypto+Private.h"
#import "ARTInternalLog.h"

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

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceSecretKey = @"ARTDeviceSecret";
NSString *const ARTDeviceIdentityTokenKey = @"ARTDeviceIdentityToken";
NSString *const ARTAPNSDeviceTokenKey = @"ARTAPNSDeviceToken";
NSString *const ARTClientIdKey = @"ARTClientId";

NSString *const ARTAPNSDeviceDefaultTokenType = @"default";
NSString *const ARTAPNSDeviceLocationTokenType = @"location";

NSString* ARTAPNSDeviceTokenKeyOfType(NSString *tokenType) {
    return [ARTAPNSDeviceTokenKey stringByAppendingFormat:@"-%@", tokenType ?: ARTAPNSDeviceDefaultTokenType];
}

@interface ARTLocalDevice ()

@property (nullable, nonatomic, readonly) ARTInternalLog *logger;

@end

@implementation ARTLocalDevice

- (instancetype)initWithStorage:(id<ARTDeviceStorage>)storage logger:(nullable ARTInternalLog *)logger {
    ARTLogVerbose(logger, @"BEGIN ARTLocalDevice initWithStorage:logger:");
    ARTLogVerbose(logger, @"BEGIN [super init]");
    if (self = [super init]) {
        ARTLogVerbose(logger, @"END [super init]");
        self.storage = storage;
        _logger = logger;
    }
    ARTLogVerbose(logger, @"END ARTLocalDevice initWithStorage:logger:");
    return self;
}

- (void)generateAndPersistPairOfDeviceIdAndSecret {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice generateAndPersistPairOfDeviceIdAndSecret");
    ARTLogVerbose(self.logger, @"BEGIN [self.class generateIdWithLogger:]");
    self.id = [self.class generateIdWithLogger:self.logger];
    ARTLogVerbose(self.logger, @"END [self.class generateIdWithLogger:]");
    ARTLogVerbose(self.logger, @"BEGIN [self.class generateSecretWithLogger:]");
    self.secret = [self.class generateSecretWithLogger:self.logger];
    ARTLogVerbose(self.logger, @"END [self.class generateSecretWithLogger:]");

    ARTLogVerbose(self.logger, @"BEGIN [_storage setObject:self.id forKey:ARTDeviceIdKey]");
    [_storage setObject:self.id forKey:ARTDeviceIdKey];
    ARTLogVerbose(self.logger, @"END [_storage setObject:self.id forKey:ARTDeviceIdKey]");
    ARTLogVerbose(self.logger, @"BEGIN [_storage setSecret:self.secret forDevice:self.id]");
    [_storage setSecret:self.secret forDevice:self.id];
    ARTLogVerbose(self.logger, @"END [_storage setSecret:self.secret forDevice:self.id]");
    ARTLogVerbose(self.logger, @"END ARTLocalDevice generateAndPersistPairOfDeviceIdAndSecret");
}

+ (instancetype)deviceWithStorage:(id<ARTDeviceStorage>)storage logger:(nullable ARTInternalLog *)logger {
    ARTLogVerbose(logger, @"BEGIN ARTLocalDevice deviceWithStorage:logger:");
    ARTLogVerbose(logger, @"BEGIN [[ARTLocalDevice alloc] initWithStorage:storage logger:logger]");
    ARTLocalDevice *device = [[ARTLocalDevice alloc] initWithStorage:storage logger:logger];
    ARTLogVerbose(logger, @"END [[ARTLocalDevice alloc] initWithStorage:storage logger:logger]");
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

    ARTLogVerbose(logger, @"BEGIN [storage objectForKey:ARTDeviceIdKey]");
    NSString *deviceId = [storage objectForKey:ARTDeviceIdKey];
    ARTLogVerbose(logger, @"END [storage objectForKey:ARTDeviceIdKey]");
    ARTLogVerbose(logger, @"BEGIN [storage secretForDevice:deviceId]");
    NSString *deviceSecret = deviceId == nil ? nil : [storage secretForDevice:deviceId];
    ARTLogVerbose(logger, @"END [storage secretForDevice:deviceId]");

    if (deviceId == nil || deviceSecret == nil) {
        ARTLogVerbose(logger, @"BEGIN [device generateAndPersistPairOfDeviceIdAndSecret]");
        [device generateAndPersistPairOfDeviceIdAndSecret]; // Should be removed later once spec issue #180 resolved.
        ARTLogVerbose(logger, @"END [device generateAndPersistPairOfDeviceIdAndSecret]");
    }
    else {
        device.id = deviceId;
        device.secret = deviceSecret;
    }

    ARTLogVerbose(logger, @"BEGIN [storage objectForKey:ARTDeviceIdentityTokenKey]");
    id identityTokenDetailsInfo = [storage objectForKey:ARTDeviceIdentityTokenKey];
    ARTLogVerbose(logger, @"END [storage objectForKey:ARTDeviceIdentityTokenKey]");
    ARTLogVerbose(logger, @"BEGIN [ARTDeviceIdentityTokenDetails unarchive:identityTokenDetailsInfo withLogger:logger]");
    ARTDeviceIdentityTokenDetails *identityTokenDetails = [ARTDeviceIdentityTokenDetails unarchive:identityTokenDetailsInfo withLogger:logger];
    ARTLogVerbose(logger, @"END [ARTDeviceIdentityTokenDetails unarchive:identityTokenDetailsInfo withLogger:logger]");
    device->_identityTokenDetails = identityTokenDetails;

    ARTLogVerbose(logger, @"BEGIN [storage objectForKey:ARTClientIdKey]");
    NSString *clientId = [storage objectForKey:ARTClientIdKey];
    ARTLogVerbose(logger, @"END [storage objectForKey:ARTClientIdKey]");
    if (clientId == nil && identityTokenDetails.clientId != nil) {
        clientId = identityTokenDetails.clientId; // Older versions of the SDK did not persist clientId, so as a fallback when loading data persisted by these versions we use the clientId of the stored identity token
        ARTLogVerbose(logger, @"BEGIN [storage setObject:clientId forKey:ARTClientIdKey]");
        [storage setObject:clientId forKey:ARTClientIdKey];
        ARTLogVerbose(logger, @"END [storage setObject:clientId forKey:ARTClientIdKey]");
    }
    device.clientId = clientId;

    NSArray *supportedTokenTypes = @[
        ARTAPNSDeviceDefaultTokenType,
        ARTAPNSDeviceLocationTokenType
    ];

    for (NSString *tokenType in supportedTokenTypes) {
        ARTLogVerbose(logger, @"BEGIN [ARTLocalDevice apnsDeviceTokenOfType:tokenType fromStorage:storage logger:logger]");
        NSString *token = [ARTLocalDevice apnsDeviceTokenOfType:tokenType fromStorage:storage logger:logger];
        ARTLogVerbose(logger, @"END [ARTLocalDevice apnsDeviceTokenOfType:tokenType fromStorage:storage logger:logger]");
        ARTLogVerbose(logger, @"BEGIN [device setAPNSDeviceToken:token tokenType:tokenType]");
        [device setAPNSDeviceToken:token tokenType:tokenType];
        ARTLogVerbose(logger, @"END [device setAPNSDeviceToken:token tokenType:tokenType]");
    }
    ARTLogVerbose(logger, @"END ARTLocalDevice deviceWithStorage:logger:");
    return device;
}

- (void)setupDetailsWithClientId:(NSString *)clientId {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice setupDetailsWithClientId:");
    NSString *deviceId = self.id;
    NSString *deviceSecret = self.secret;

    if (deviceId == nil || deviceSecret == nil) {
        ARTLogVerbose(self.logger, @"BEGIN [self generateAndPersistPairOfDeviceIdAndSecret]");
        [self generateAndPersistPairOfDeviceIdAndSecret];
        ARTLogVerbose(self.logger, @"END [self generateAndPersistPairOfDeviceIdAndSecret]");
    }

    self.clientId = clientId;
    ARTLogVerbose(self.logger, @"BEGIN [_storage setObject:clientId forKey:ARTClientIdKey]");
    [_storage setObject:clientId forKey:ARTClientIdKey];
    ARTLogVerbose(self.logger, @"END [_storage setObject:clientId forKey:ARTClientIdKey]");
    ARTLogVerbose(self.logger, @"END ARTLocalDevice setupDetailsWithClientId:");
}

- (void)resetDetails {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice resetDetails");
    // Should be replaced later to resetting device's id/secret once spec issue #180 resolved.
    ARTLogVerbose(self.logger, @"BEGIN [self generateAndPersistPairOfDeviceIdAndSecret]");
    [self generateAndPersistPairOfDeviceIdAndSecret];
    ARTLogVerbose(self.logger, @"END [self generateAndPersistPairOfDeviceIdAndSecret]");

    self.clientId = nil;
    ARTLogVerbose(self.logger, @"BEGIN [_storage setObject:nil forKey:ARTClientIdKey]");
    [_storage setObject:nil forKey:ARTClientIdKey];
    ARTLogVerbose(self.logger, @"END [_storage setObject:nil forKey:ARTClientIdKey]");
    ARTLogVerbose(self.logger, @"BEGIN [self setAndPersistIdentityTokenDetails:nil]");
    [self setAndPersistIdentityTokenDetails:nil];
    ARTLogVerbose(self.logger, @"END [self setAndPersistIdentityTokenDetails:nil]");
    NSArray *supportedTokenTypes = @[
        ARTAPNSDeviceDefaultTokenType,
        ARTAPNSDeviceLocationTokenType
    ];
    for (NSString *tokenType in supportedTokenTypes) {
        ARTLogVerbose(self.logger, @"BEGIN [self setAndPersistAPNSDeviceToken:nil tokenType:tokenType]");
        [self setAndPersistAPNSDeviceToken:nil tokenType:tokenType];
        ARTLogVerbose(self.logger, @"END [self setAndPersistAPNSDeviceToken:nil tokenType:tokenType]");
    }
    ARTLogVerbose(self.logger, @"END ARTLocalDevice resetDetails");
}

+ (NSString *)generateIdWithLogger:(nullable ARTInternalLog *)logger {
    ARTLogVerbose(logger, @"BEGIN ARTLocalDevice generateId");
    ARTLogVerbose(logger, @"BEGIN [NSUUID new]");
    NSUUID *uuid = [NSUUID new];
    ARTLogVerbose(logger, @"END [NSUUID new]");
    NSString *uuidString = uuid.UUIDString;
    ARTLogVerbose(logger, @"END ARTLocalDevice generateId");
    return uuidString;
}

+ (NSString *)generateSecretWithLogger:(nullable ARTInternalLog *)logger {
    ARTLogVerbose(logger, @"BEGIN ARTLocalDevice generateSecret");
    ARTLogVerbose(logger, @"BEGIN [ARTCrypto generateSecureRandomData:32]");
    NSData *randomData = [ARTCrypto generateSecureRandomData:32];
    ARTLogVerbose(logger, @"END [ARTCrypto generateSecureRandomData:32]");
    ARTLogVerbose(logger, @"BEGIN [ARTCrypto generateHashSHA256:randomData]");
    NSData *hash = [ARTCrypto generateHashSHA256:randomData];
    ARTLogVerbose(logger, @"END [ARTCrypto generateHashSHA256:randomData]");
    ARTLogVerbose(logger, @"BEGIN [hash base64EncodedStringWithOptions:0]");
    NSString *base64String = [hash base64EncodedStringWithOptions:0];
    ARTLogVerbose(logger, @"END [hash base64EncodedStringWithOptions:0]");
    ARTLogVerbose(logger, @"END ARTLocalDevice generateSecret");
    return base64String;
}

+ (NSString *)apnsDeviceTokenOfType:(nullable NSString *)tokenType fromStorage:(id<ARTDeviceStorage>)storage logger:(nullable ARTInternalLog *)logger {
    ARTLogVerbose(logger, @"BEGIN ARTLocalDevice apnsDeviceTokenOfType:fromStorage:");
    ARTLogVerbose(logger, @"BEGIN ARTAPNSDeviceTokenKeyOfType(tokenType)");
    NSString *key = ARTAPNSDeviceTokenKeyOfType(tokenType);
    ARTLogVerbose(logger, @"END ARTAPNSDeviceTokenKeyOfType(tokenType)");
    ARTLogVerbose(logger, @"BEGIN [storage objectForKey:key]");
    NSString *token = [storage objectForKey:key];
    ARTLogVerbose(logger, @"END [storage objectForKey:key]");
    ARTLogVerbose(logger, @"BEGIN [tokenType isEqualToString:ARTAPNSDeviceDefaultTokenType]");
    BOOL isDefaultTokenType = [tokenType isEqualToString:ARTAPNSDeviceDefaultTokenType];
    ARTLogVerbose(logger, @"END [tokenType isEqualToString:ARTAPNSDeviceDefaultTokenType]");
    if (isDefaultTokenType && token == nil) {
        ARTLogVerbose(logger, @"BEGIN [storage objectForKey:ARTAPNSDeviceTokenKey]");
        token = [storage objectForKey:ARTAPNSDeviceTokenKey]; // Read legacy token
        ARTLogVerbose(logger, @"END [storage objectForKey:ARTAPNSDeviceTokenKey]");
    }
    ARTLogVerbose(logger, @"END ARTLocalDevice apnsDeviceTokenOfType:fromStorage:");
    return token;
}

- (NSString *)apnsDeviceToken {
    NSDictionary *deviceTokens = (NSDictionary *)self.push.recipient[@"apnsDeviceTokens"];
    return deviceTokens[ARTAPNSDeviceDefaultTokenType];
}

- (void)setAPNSDeviceToken:(NSString *)token tokenType:(NSString *)tokenType {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice setAPNSDeviceToken:tokenType:");
    ARTLogVerbose(self.logger, @"BEGIN [(self.push.recipient[@\"apnsDeviceTokens\"] ?: (token != nil ? @{} : nil)) mutableCopy]");
    NSMutableDictionary *deviceTokens = [(self.push.recipient[@"apnsDeviceTokens"] ?: (token != nil ? @{} : nil)) mutableCopy];
    ARTLogVerbose(self.logger, @"END [(self.push.recipient[@\"apnsDeviceTokens\"] ?: (token != nil ? @{} : nil)) mutableCopy]");
    deviceTokens[tokenType] = token;
    ARTLogVerbose(self.logger, @"BEGIN [deviceTokens copy]");
    NSDictionary *copiedTokens = [deviceTokens copy];
    ARTLogVerbose(self.logger, @"END [deviceTokens copy]");
    self.push.recipient[@"apnsDeviceTokens"] = copiedTokens;
    ARTLogVerbose(self.logger, @"END ARTLocalDevice setAPNSDeviceToken:tokenType:");
}

- (void)setAndPersistAPNSDeviceToken:(NSString *)token tokenType:(NSString *)tokenType {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice setAndPersistAPNSDeviceToken:tokenType:");
    ARTLogVerbose(self.logger, @"BEGIN ARTAPNSDeviceTokenKeyOfType(tokenType)");
    NSString *key = ARTAPNSDeviceTokenKeyOfType(tokenType);
    ARTLogVerbose(self.logger, @"END ARTAPNSDeviceTokenKeyOfType(tokenType)");
    ARTLogVerbose(self.logger, @"BEGIN [self.storage setObject:token forKey:key]");
    [self.storage setObject:token forKey:key];
    ARTLogVerbose(self.logger, @"END [self.storage setObject:token forKey:key]");
    ARTLogVerbose(self.logger, @"BEGIN [self setAPNSDeviceToken:token tokenType:tokenType]");
    [self setAPNSDeviceToken:token tokenType:tokenType];
    ARTLogVerbose(self.logger, @"END [self setAPNSDeviceToken:token tokenType:tokenType]");
    ARTLogVerbose(self.logger, @"END ARTLocalDevice setAndPersistAPNSDeviceToken:tokenType:");
}

- (void)setAndPersistAPNSDeviceToken:(NSString *)token {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice setAndPersistAPNSDeviceToken:");
    ARTLogVerbose(self.logger, @"BEGIN [self setAndPersistAPNSDeviceToken:token tokenType:ARTAPNSDeviceDefaultTokenType]");
    [self setAndPersistAPNSDeviceToken:token tokenType:ARTAPNSDeviceDefaultTokenType];
    ARTLogVerbose(self.logger, @"END [self setAndPersistAPNSDeviceToken:token tokenType:ARTAPNSDeviceDefaultTokenType]");
    ARTLogVerbose(self.logger, @"END ARTLocalDevice setAndPersistAPNSDeviceToken:");
}

- (void)setAndPersistIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)tokenDetails {
    ARTLogVerbose(self.logger, @"BEGIN ARTLocalDevice setAndPersistIdentityTokenDetails:");
    ARTLogVerbose(self.logger, @"BEGIN [tokenDetails archiveWithLogger:self.logger]");
    id archivedTokenDetails = [tokenDetails archiveWithLogger:self.logger];
    ARTLogVerbose(self.logger, @"END [tokenDetails archiveWithLogger:self.logger]");
    ARTLogVerbose(self.logger, @"BEGIN [self.storage setObject:archivedTokenDetails forKey:ARTDeviceIdentityTokenKey]");
    [self.storage setObject:archivedTokenDetails
                     forKey:ARTDeviceIdentityTokenKey];
    ARTLogVerbose(self.logger, @"END [self.storage setObject:archivedTokenDetails forKey:ARTDeviceIdentityTokenKey]");
    _identityTokenDetails = tokenDetails;
    if (self.clientId == nil) {
        self.clientId = tokenDetails.clientId;
        ARTLogVerbose(self.logger, @"BEGIN [self.storage setObject:tokenDetails.clientId forKey:ARTClientIdKey]");
        [self.storage setObject:tokenDetails.clientId forKey:ARTClientIdKey];
        ARTLogVerbose(self.logger, @"END [self.storage setObject:tokenDetails.clientId forKey:ARTClientIdKey]");
    }
    ARTLogVerbose(self.logger, @"END ARTLocalDevice setAndPersistIdentityTokenDetails:");
}

- (BOOL)isRegistered {
    return _identityTokenDetails != nil;
}

@end
