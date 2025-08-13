#import <Ably/ARTClientOptions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol APLiveObjectsInternalPluginProtocol;

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

// MARK: - Plugins

/// The plugin that channels should use to access LiveObjects functionality.
@property (nullable, readonly) id<APLiveObjectsInternalPluginProtocol> liveObjectsPlugin;

// MARK: - Options for plugins

/// Provides the implementation for `-[APPluginAPI setPluginOptionsValue:forKey:options:]`. See documentation for that method.
- (void)setPluginOptionsValue:(id)value forKey:(NSString *)key;
/// Provides the implementation for `-[APPluginAPI pluginOptionsValueForKey:options:]`. See documentation for that method.
- (nullable id)pluginOptionsValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
