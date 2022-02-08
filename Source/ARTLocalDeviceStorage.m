#import "ARTLocalDeviceStorage.h"
#import "ARTLog.h"
#import "ARTLocalDevice+Private.h"
#import "ARTPropertyListFileStorage.h"

@implementation ARTLocalDeviceStorage {
    ARTLog *_logger;
    ARTPropertyListFileStorage *_fileStorage;
    // TODO should we be aiming to use the existing synchronisation that's there?
    dispatch_queue_t _fileStorageAccessQueue;
}

- (instancetype)initWithLogger:(ARTLog *)logger {
    if (self = [super init]) {
        _logger = logger;
        _fileStorage = [[ARTPropertyListFileStorage alloc] initWithPropertyListFileURL:ARTPropertyListFileStorage.defaultPropertyListFileURL];
        _fileStorageAccessQueue = dispatch_queue_create("io.ably.filestorage", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (instancetype)newWithLogger:(ARTLog *)logger {
    return [[self alloc] initWithLogger:logger];
}

- (BOOL)getObject:(_Nullable id * _Nullable)ptr forKey:(NSString *)key error:(NSError **)error {
    __block BOOL result;
    __block id object;
    __block id localError;
    dispatch_sync(_fileStorageAccessQueue, ^{
        result = [_fileStorage getObject:&object forKey:key error:&localError];
    });
    
    if (ptr) {
        *ptr = object;
    }
    
    if (error) {
        *error = localError;
    }
    
    return result;
}

- (BOOL)setObject:(nullable id)value forKey:(NSString *)key error:(NSError **)error {
    __block BOOL result;
    __block id localError;
    dispatch_sync(_fileStorageAccessQueue, ^{
        result = [_fileStorage setObject:value forKey:key error:&localError];
    });
    
    if (error) {
        *error = localError;
    }
    
    return result;
}

- (BOOL)getSecret:(NSString * _Nullable * _Nullable)ptr forDevice:(ARTDeviceId *)deviceId error:(NSError **)error {
    NSError *localError = nil;
    NSString *value = [self keychainGetPasswordForService:ARTDeviceSecretKey account:(NSString *)deviceId error:&localError];
    
    if (error && localError) {
        *error = localError;
    }

    if ([localError code] == errSecItemNotFound) {
        [_logger debug:__FILE__ line:__LINE__ message:@"Device Secret not found"];
    }
    else if (localError) {
        [_logger error:@"Device Secret couldn't be read (%@)", [localError localizedDescription]];
    }
    
    if (ptr) {
        *ptr = value;
    }

    return localError == nil;
}

- (BOOL)setSecret:(NSString *)value forDevice:(ARTDeviceId *)deviceId error:(NSError **)error {
    NSError *localError = nil;
    if (value == nil) {
        if (![self keychainDeletePasswordForService:ARTDeviceSecretKey account:(NSString *)deviceId error:&localError]) {
            if ([localError code] == errSecItemNotFound) {
                [_logger warn:@"Device Secret can't be deleted because it doesn't exist"];
            }
            else if (localError) {
                [_logger error:@"Device Secret couldn't be updated (%@)", [localError localizedDescription]];
            }
            
            if (error) {
                *error = localError;
            }
            
            return NO;
        }
    }
    else {
        if (![self keychainSetPassword:value forService:ARTDeviceSecretKey account:(NSString *)deviceId error:&localError]) {
            if (localError) {
                [_logger error:@"Device Secret couldn't be updated (%@)", [localError localizedDescription]];
            }
            
            if (error) {
                *error = localError;
            }
            
            return NO;
        }
    }
    
    return YES;
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
    OSStatus status;
    #if TARGET_OS_IPHONE
    status = SecItemDelete((__bridge CFDictionaryRef)query);
    #else
    CFTypeRef result = NULL;
    [query setObject:@YES forKey:(__bridge id)kSecReturnRef];
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess) {
        status = SecKeychainItemDelete((SecKeychainItemRef)result);
        CFRelease(result);
    }
    #endif

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
