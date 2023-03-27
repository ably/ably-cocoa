#import <Ably/ARTClientOptions.h>
#import <Ably/ARTInternalLogHandler.h>

@protocol ARTVersion2LogHandler;

@interface ARTClientOptions ()

@property (nullable, strong, nonatomic) NSString *channelNamePrefix;

/**
 If non-nil, overrides any configuration from this client options instance’s `logHandler` and `logLevel` (TODO check I mean this about logLevel).
 */
@property (nullable, nonatomic) id<ARTVersion2LogHandler> version2LogHandler;

@property (readonly) BOOL isProductionEnvironment;
@property (readonly) BOOL hasEnvironment;
@property (readonly) BOOL hasEnvironmentDifferentThanProduction;
@property (readonly) BOOL hasCustomRestHost;
@property (readonly) BOOL hasDefaultRestHost;
@property (readonly) BOOL hasCustomRealtimeHost;
@property (readonly) BOOL hasDefaultRealtimeHost;
@property (readonly) BOOL hasCustomPort;
@property (readonly) BOOL hasCustomTlsPort;

+ (void)setDefaultEnvironment:(NSString *_Nullable)environment;
+ (BOOL)getDefaultIdempotentRestPublishingForVersion:(NSString *_Nonnull)version;
- (NSURLComponents *_Nonnull)restUrlComponents;

@end
