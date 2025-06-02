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

@end

NS_ASSUME_NONNULL_END
