#import "NSURLRequest+ARTPaginated.h"

@implementation NSURLRequest (ARTPaginated)

+ (NSURLRequest *)requestWithPath:(NSString *)path relativeTo:(NSURLRequest *)request {
    if (!path) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:path relativeToURL:request.URL];
    return [NSURLRequest requestWithURL:url];
}

@end
