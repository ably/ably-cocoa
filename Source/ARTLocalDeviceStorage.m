#import "ARTLocalDeviceStorage.h"
#import "ARTInternalLog.h"
#import "ARTLocalDevice+Private.h"

@implementation ARTLocalDeviceStorage {
    ARTInternalLog *_logger;
    BOOL _logValues;
}

- (instancetype)initWithLogger:(ARTInternalLog *)logger logValues:(BOOL)logValues {
    if (self = [super init]) {
        _logger = logger;
        _logValues = logValues;
    }
    return self;
}

+ (instancetype)newWithLogger:(ARTInternalLog *)logger logValues:(BOOL)logValues {
    return [[self alloc] initWithLogger:logger logValues:logValues];
}

- (id)valueToLogForValue:(id)value {
    if (!_logValues) {
        return @"(retracted)";
    }
    if ([value isKindOfClass:[NSData class]]) {
        // `NSData`'s default `description` is a hex-ish dump that's
        // awkward to read or paste back for inspection. Render as
        // base64 with a prefix that makes the encoding explicit.
        return [NSString stringWithFormat:@"<NSData base64:%@>", [(NSData *)value base64EncodedStringWithOptions:0]];
    }
    return value;
}

- (nullable id)objectForKey:(NSString *)key {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    if (value == nil) {
        ARTLogDebug(_logger, @"UserDefaults read miss for key %@", key);
    }
    else {
        ARTLogDebug(_logger, @"UserDefaults read hit for key %@: %@", key, [self valueToLogForValue:value]);
    }
    return value;
}

- (void)setObject:(nullable id)value forKey:(NSString *)key {
    [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
    if (value == nil) {
        ARTLogDebug(_logger, @"UserDefaults deleted for key %@", key);
    }
    else {
        ARTLogDebug(_logger, @"UserDefaults written for key %@: %@", key, [self valueToLogForValue:value]);
    }
}

- (NSString *)secretForDevice:(ARTDeviceId *)deviceId {
    NSError *error = nil;
    NSString *value = [self keychainGetPasswordForService:ARTDeviceSecretKey account:(NSString *)deviceId error:&error];

    if ([error code] == errSecItemNotFound) {
        ARTLogDebug(_logger, @"Device Secret read miss for device %@", deviceId);
    }
    else if (error) {
        ARTLogError(_logger, @"Device Secret couldn't be read for device %@ (%@)", deviceId, [error localizedDescription]);
    }
    else {
        ARTLogDebug(_logger, @"Device Secret read hit for device %@: %@", deviceId, [self valueToLogForValue:value]);
    }

    return value;
}

- (void)setSecret:(NSString *)value forDevice:(ARTDeviceId *)deviceId {
    NSError *error = nil;
    if (value == nil) {
        [self keychainDeletePasswordForService:ARTDeviceSecretKey account:(NSString *)deviceId error:&error];

        if ([error code] == errSecItemNotFound) {
            ARTLogWarn(_logger, @"Device Secret can't be deleted for device %@ because it doesn't exist", deviceId);
        }
        else if (error) {
            ARTLogError(_logger, @"Device Secret couldn't be deleted for device %@ (%@)", deviceId, [error localizedDescription]);
        }
        else {
            ARTLogDebug(_logger, @"Device Secret deleted for device %@", deviceId);
        }
    }
    else {
        [self keychainSetPassword:value forService:ARTDeviceSecretKey account:(NSString *)deviceId error:&error];

        if (error) {
            ARTLogError(_logger, @"Device Secret couldn't be written for device %@: %@ (%@)", deviceId, [self valueToLogForValue:value], [error localizedDescription]);
        }
        else {
            ARTLogDebug(_logger, @"Device Secret written for device %@: %@", deviceId, [self valueToLogForValue:value]);
        }
    }
}

#pragma mark - Keychain

- (nonnull NSMutableDictionary *)newKeychainQueryForService:(nonnull NSString *)serviceName account:(nonnull NSString *)account {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    [dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [dictionary setObject:serviceName forKey:(__bridge id)kSecAttrService];
    [dictionary setObject:account forKey:(__bridge id)kSecAttrAccount];
#if TARGET_OS_IPHONE
    [dictionary setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
#endif
    return dictionary;
}

- (nonnull NSError *)keychainErrorWithCode:(OSStatus)status {
    NSString *message = nil;
    #if TARGET_OS_IPHONE
    switch (status) {
        case errSecUnimplemented: {
            message = @"errSecUnimplemented";
            break;
        }
        case errSecParam: {
            message = @"errSecParam";
            break;
        }
        case errSecAllocate: {
            message = @"errSecAllocate";
            break;
        }
        case errSecNotAvailable: {
            message = @"errSecNotAvailable";
            break;
        }
        case errSecDuplicateItem: {
            message = @"errSecDuplicateItem";
            break;
        }
        case errSecItemNotFound: {
            message = @"errSecItemNotFound";
            break;
        }
        case errSecInteractionNotAllowed: {
            message = @"errSecInteractionNotAllowed";
            break;
        }
        case errSecDecode: {
            message = @"errSecDecode";
            break;
        }
        case errSecAuthFailed: {
            message = @"errSecAuthFailed";
            break;
        }
        default: {
            message = @"errSecDefault";
        }
    }
    #else
    message = (__bridge_transfer NSString *)SecCopyErrorMessageString(status, NULL);
    #endif
    NSDictionary *userInfo = nil;
    if (message) {
        userInfo = @{ NSLocalizedDescriptionKey : message };
    }
    return [NSError errorWithDomain:[NSString stringWithFormat:@"%@.%@", ARTAblyErrorDomain, @"Keychain"] code:status userInfo:userInfo];
}

- (nullable NSString *)keychainGetPasswordForService:(nonnull NSString *)serviceName account:(nonnull NSString *)account error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *query = [self newKeychainQueryForService:serviceName account:account];

    [query setObject:@YES forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    if (status != errSecSuccess) {
        if (error) {
            *error = [self keychainErrorWithCode:status];
        }
    }
    else {
        NSData *passwordData = (__bridge_transfer NSData *)result;
        if ([passwordData length]) {
            return [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        }
    }

    return nil;
}

- (BOOL)keychainDeletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *query = [self newKeychainQueryForService:serviceName account:account];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status != errSecSuccess && error != NULL) {
        *error = [self keychainErrorWithCode:status];
    }
    return (status == errSecSuccess);
}

- (BOOL)keychainSetPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *query = nil;
    NSMutableDictionary *searchQuery = [self newKeychainQueryForService:serviceName account:account];
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];

    OSStatus status;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, nil);
    if (status == errSecSuccess) { //item already exists, update it.
        query = [[NSMutableDictionary alloc] init];
        [query setObject:passwordData forKey:(__bridge id)kSecValueData];
        status = SecItemUpdate((__bridge CFDictionaryRef)(searchQuery), (__bridge CFDictionaryRef)(query));
    }
    else if (status == errSecItemNotFound) { //item not found, create it.
        query = [self newKeychainQueryForService:serviceName account:account];
        [query setObject:passwordData forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }

    if (status != errSecSuccess && error != NULL) {
        *error = [self keychainErrorWithCode:status];
    }

    return (status == errSecSuccess);
}

@end
