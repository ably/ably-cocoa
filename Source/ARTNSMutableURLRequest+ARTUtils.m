#import "ARTNSMutableURLRequest+ARTUtils.h"

@implementation NSMutableURLRequest (ARTUtils)

- (void)setQueryItemNamed:(NSString *)name withValue:(NSString *)value {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:YES];
    if (components == nil) {
        return;
    }
    
    NSMutableArray<NSURLQueryItem *> *mutableQueryItems = [NSMutableArray arrayWithArray:components.queryItems ?: @[]];
    
    // Remove existing query item with the same name if it exists
    NSMutableIndexSet *indicesToRemove = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < mutableQueryItems.count; i++) {
        if ([mutableQueryItems[i].name isEqualToString:name]) {
            [indicesToRemove addIndex:i];
        }
    }
    [mutableQueryItems removeObjectsAtIndexes:indicesToRemove];
    
    // Add the new query item
    NSURLQueryItem *newItem = [NSURLQueryItem queryItemWithName:name value:value];
    [mutableQueryItems addObject:newItem];
    
    components.queryItems = mutableQueryItems;
    
    NSURL *modifiedURL = components.URL;
    if (modifiedURL != nil) {
        self.URL = modifiedURL;
    }
}

- (void)replaceHostWith:(NSString *)host {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:YES];
    components.host = host;
    
    if(components != nil) {
        self.URL = components.URL;
    }
}

@end
