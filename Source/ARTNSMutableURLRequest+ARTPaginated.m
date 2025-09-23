#import "ARTNSMutableURLRequest+ARTPaginated.h"

@implementation NSMutableURLRequest (ARTPaginated)

+ (NSMutableURLRequest *)requestWithPath:(NSString *)path relativeTo:(NSURLRequest *)request {
    if (!path) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:path relativeToURL:request.URL];
    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:url];

    // Copy headers from the original request to preserve custom headers (like X-Ably-Version)
    [newRequest setAllHTTPHeaderFields:[request allHTTPHeaderFields]];

    return newRequest;
}

@end
