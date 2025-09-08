#import "NSURLRequest+ARTRest.h"

#import "ARTEncoder.h"

@implementation NSURLRequest (ARTRest)

- (NSURLRequest *)settingAcceptHeader:(id<ARTEncoder>)defaultEncoder encoders:(NSDictionary<NSString *, id<ARTEncoder>> *)encoders {
    NSMutableArray *allEncoders = [NSMutableArray arrayWithArray:[encoders.allValues valueForKeyPath:@"mimeType"]];
    NSString *defaultMimetype = [defaultEncoder mimeType];
    // Make the mime type of the default encoder the first element of the Accept header field
    [allEncoders removeObject:defaultMimetype];
    [allEncoders insertObject:defaultMimetype atIndex:0];
    NSString *accept = [allEncoders componentsJoinedByString:@","];
    NSMutableURLRequest *mutableRequest = [self mutableCopy];
    [mutableRequest setValue:accept forHTTPHeaderField:@"Accept"];
    return [mutableRequest copy];
}

@end
