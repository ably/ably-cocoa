//
//  ARTDeviceIdentityToken.m
//  Ably
//
//  Created by Ricardo Pereira on 21/03/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTDeviceIdentityTokenDetails.h"

NSString *const ARTCoderTokenKey = @"token";
NSString *const ARTCoderIssuedKey = @"issued";
NSString *const ARTCoderExpiresKey = @"expires";
NSString *const ARTCoderCapabilityKey = @"capability";
NSString *const ARTCoderDeviceIdKey = @"deviceId";

@implementation ARTDeviceIdentityTokenDetails

- (instancetype)initWithToken:(NSString *)token issued:(NSDate *)issued expires:(NSDate *)expires capability:(NSString *)capability deviceId:(NSString *)deviceId {
    if (self = [super init]) {
        _token  = token;
        _issued = issued;
        _expires = expires;
        _capability = capability;
        _deviceId = deviceId;
    }
    return self;
}

// MARK: NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t token: %@; \n\t issued: %@; \n\t expires: %@; \n\t deviceId: %@;", [super description], self.token, self.issued, self.expires, self.deviceId];
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

    _token = [aDecoder decodeObjectForKey:ARTCoderTokenKey];
    _issued = [aDecoder decodeObjectForKey:ARTCoderIssuedKey];
    _expires = [aDecoder decodeObjectForKey:ARTCoderExpiresKey];
    _capability = [aDecoder decodeObjectForKey:ARTCoderCapabilityKey];
    _deviceId = [aDecoder decodeObjectForKey:ARTCoderDeviceIdKey];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:ARTCoderTokenKey];
    [aCoder encodeObject:self.issued forKey:ARTCoderIssuedKey];
    [aCoder encodeObject:self.expires forKey:ARTCoderExpiresKey];
    [aCoder encodeObject:self.capability forKey:ARTCoderCapabilityKey];
    [aCoder encodeObject:self.deviceId forKey:ARTCoderDeviceIdKey];
}

#pragma mark - Archive/Unarchive

- (NSData *)archive {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+ (ARTDeviceIdentityTokenDetails *)unarchive:(NSData *)data {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
