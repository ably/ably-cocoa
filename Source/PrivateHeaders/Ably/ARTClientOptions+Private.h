#import <Ably/ARTClientOptions.h>

#ifdef ABLY_SUPPORTS_PLUGINS
@import _AblyPluginSupportPrivate;
#endif

@class ARTDomainSelector;

NS_ASSUME_NONNULL_BEGIN

#ifdef ABLY_SUPPORTS_PLUGINS
@interface ARTClientOptions () <APPublicClientOptions>
@end
#endif

@interface ARTClientOptions ()

@property (readonly, nonatomic) ARTDomainSelector *domainSelector;

+ (void)setDefaultEndpoint:(nullable NSString *)endpoint;
+ (BOOL)getDefaultIdempotentRestPublishingForVersion:(NSString *)version;
- (NSURLComponents *)restUrlComponents;
- (NSURL*)realtimeUrlForHost:(NSString *)host; // helps obtain url with an alternative host without changing other params

// MARK: - Plugins

#ifdef ABLY_SUPPORTS_PLUGINS
/// The plugin that channels should use to access LiveObjects functionality.
@property (nullable, readonly) id<APLiveObjectsInternalPluginProtocol> liveObjectsPlugin;
#endif

// MARK: - Options for plugins

/// Provides the implementation for `-[ARTPluginAPI setPluginOptionsValue:forKey:options:]`. See documentation for that method in `APPluginAPIProtocol`.
- (void)setPluginOptionsValue:(id)value forKey:(NSString *)key;
/// Provides the implementation for `-[ARTPluginAPI pluginOptionsValueForKey:options:]`. See documentation for that method in `APPluginAPIProtocol`.
- (nullable id)pluginOptionsValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
