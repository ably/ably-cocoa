#import "ARTTypes.h"
#import "ARTTypes+Private.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTDeviceIdentityTokenDetails+Private.h"

NSString *const ARTCoderTokenKey = @"token";
NSString *const ARTCoderIssuedKey = @"issued";
NSString *const ARTCoderExpiresKey = @"expires";
NSString *const ARTCoderCapabilityKey = @"capability";
NSString *const ARTCoderClientIdKey = @"clientId";

@implementation ARTDeviceIdentityTokenDetails

- (instancetype)initWithToken:(NSString *)token issued:(NSDate *)issued expires:(NSDate *)expires capability:(NSString *)capability clientId:(NSString *)clientId {
    if (self = [super init]) {
        _token  = token;
        _issued = issued;
        _expires = expires;
        _capability = capability;
        _clientId = clientId;
    }
    return self;
}

// MARK: NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t token: %@; \n\t issued: %@; \n\t expires: %@; \n\t clientId: %@;", [super description], self.token, self.issued, self.expires, self.clientId];
}

- (id)copyWithZone:(NSZone *)zone {
    // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
    return self;
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }

    _token = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARTCoderTokenKey];
    _issued = [aDecoder decodeObjectOfClass:[NSDate class] forKey:ARTCoderIssuedKey];
    _expires = [aDecoder decodeObjectOfClass:[NSDate class] forKey:ARTCoderExpiresKey];
    _capability = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARTCoderCapabilityKey];
    _clientId = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARTCoderClientIdKey];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:ARTCoderTokenKey];
    [aCoder encodeObject:self.issued forKey:ARTCoderIssuedKey];
    [aCoder encodeObject:self.expires forKey:ARTCoderExpiresKey];
    [aCoder encodeObject:self.capability forKey:ARTCoderCapabilityKey];
    [aCoder encodeObject:self.clientId forKey:ARTCoderClientIdKey];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return true;
}

#pragma mark - Archive/Unarchive

- (NSData *)archiveWithLogger:(nullable ARTInternalLog *)logger {
    return [self art_archiveWithLogger:logger];
}

+ (ARTDeviceIdentityTokenDetails *)unarchive:(NSData *)data withLogger:(nullable ARTInternalLog *)logger {
    return [self art_unarchiveFromData:data withLogger:logger];
}

@end
