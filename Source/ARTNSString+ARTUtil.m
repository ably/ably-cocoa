#import "ARTNSString+ARTUtil.h"

@implementation NSString (ARTUtil)

+ (NSString *)nilToEmpty:(NSString*)aString {
    if ([aString length] == 0) {
        return @"";
    }
    return aString;
}

- (BOOL)isEmptyString {
    return [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

- (BOOL)isNotEmptyString {
    return ![self isEmptyString];
}

- (NSString *)encodePathSegment {
    // Source: https://datatracker.ietf.org/doc/html/rfc3986#section-3.3
    // i.e. segment = unreserved / pct-encoded / sub-delims / ":" / "@", where
    //  unreserved = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~
    //  pct-encoded = %XX
    //  sub-delims = !$&'()*+,;=
    NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~!$&'()*+,;=:@"];
    NSString *escaped = [self stringByAddingPercentEncodingWithAllowedCharacters:allowedSet];
    if (!escaped) {
        [NSException raise:NSInternalInconsistencyException format:@"String '%@' can't be percent encoded.", self];
    }
    return escaped;
}

@end
