#import "NSURLRequest+ARTUtils.h"

@implementation NSURLRequest (ARTUtils)

- (NSURLRequest *)appendingQueryItem:(NSURLQueryItem *)item {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:YES];
    if(components == nil) {
        return self;
    }
    
    NSMutableArray<NSURLQueryItem *> *mutableQueryItems = [NSMutableArray arrayWithArray:components.queryItems];
    [mutableQueryItems addObject:item];
    components.queryItems = mutableQueryItems;
    
    NSURL *modifiedURL = components.URL;
    if (modifiedURL != nil) {
        NSMutableURLRequest *mutableRequest = [self mutableCopy];
        mutableRequest.URL = modifiedURL;
        return [mutableRequest copy];
    }
    return self;
}

- (NSURLRequest *)replacingHostWith:(NSString *)host {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:YES];
    components.host = host;
    
    if(components != nil && components.URL != nil) {
        NSMutableURLRequest *mutableRequest = [self mutableCopy];
        mutableRequest.URL = components.URL;
        return [mutableRequest copy];
    }
    return self;
}

@end
