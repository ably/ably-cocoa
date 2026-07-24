#import "APDependencyStore.h"

@interface APDependencyStore ()

@property (nullable, atomic) id<APPluginAPIProtocol> pluginAPI;

@end

@implementation APDependencyStore

+ (APDependencyStore *)sharedInstance {
    static APDependencyStore *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[APDependencyStore alloc] init];
    });

    return sharedInstance;
}

- (void)registerPluginAPI:(id<APPluginAPIProtocol>)pluginAPI {
    self.pluginAPI = pluginAPI;
}

- (id<APPluginAPIProtocol>)fetchPluginAPI {
    id<APPluginAPIProtocol> pluginAPI = self.pluginAPI;

    if (!pluginAPI) {
        [NSException raise:NSInternalInconsistencyException format:@"-fetchPluginAPI called before -registerPluginAPI:"];
    }

    return pluginAPI;
}

@end
