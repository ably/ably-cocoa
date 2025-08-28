#import <Ably/ARTClientOptions.h>

#ifdef ABLY_SUPPORTS_PLUGINS
@import _AblyPluginSupportPrivate;
#endif

NS_ASSUME_NONNULL_BEGIN

#ifdef ABLY_SUPPORTS_PLUGINS
@interface ARTClientOptions () <APPublicClientOptions>
@end
#endif

@interface ARTClientOptions ()

@property (readonly) BOOL isProductionEnvironment;
@property (readonly) BOOL hasEnvironment;
@property (readonly) BOOL hasEnvironmentDifferentThanProduction;
@property (readonly) BOOL hasCustomRestHost;
@property (readonly) BOOL hasDefaultRestHost;
@property (readonly) BOOL hasCustomRealtimeHost;
@property (readonly) BOOL hasDefaultRealtimeHost;
@property (readonly) BOOL hasCustomPort;
@property (readonly) BOOL hasCustomTlsPort;

+ (void)setDefaultEnvironment:(nullable NSString *)environment;
+ (BOOL)getDefaultIdempotentRestPublishingForVersion:(NSString *)version;
- (NSURLComponents *)restUrlComponents;

// MARK: - Endpoint Support

/// Returns the effective endpoint, defaulting to "main" if not set
- (NSString *)effectiveEndpoint;

/// Checks if the given endpoint is a FQDN, IP address, or localhost
- (BOOL)isEndpointFQDN:(NSString *)endpoint;

/// Converts an endpoint to a primary domain name according to REC1b
- (NSString *)primaryDomainFromEndpoint:(NSString *)endpoint;

/// Gets fallback hosts for the given endpoint according to REC2c
- (NSArray<NSString *> *)endpointFallbackHosts:(NSString *)endpoint;

/// Generates fallback hostnames for a routing policy and domain
- (NSArray<NSString *> *)endpointFallbacks:(NSString *)routingPolicyId domain:(NSString *)domain;

/// Validates that endpoint and legacy options are not used together
- (void)validateOptions;

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
