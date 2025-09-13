#import "ARTClientOptions+Private.h"
#import "ARTClientOptions+TestConfiguration.h"
#import "ARTAuthOptions+Private.h"

#import "ARTDefault.h"
#import "ARTDefault+Private.h"
#import "ARTStatus.h"
#import "ARTTokenParams.h"
#import "ARTStringifiable.h"
#import "ARTNSString+ARTUtil.h"
#import "ARTTestClientOptions.h"
#import "ARTNSArray+ARTFunctional.h"

#ifdef ABLY_SUPPORTS_PLUGINS
@import _AblyPluginSupportPrivate;
#import "ARTPluginAPI.h"
#endif

const ARTPluginName ARTPluginNameLiveObjects = @"LiveObjects";

NSString *ARTDefaultEndpoint = nil;

@interface ARTClientOptions ()

@property (nonatomic) NSMutableDictionary<NSString *, id> *pluginData;

- (instancetype)initDefaults;

@end

@implementation ARTClientOptions {
    NSString *_endpoint;
    NSString *_restHost;
    NSString *_realtimeHost;
    NSString *_environment;
}

- (instancetype)initDefaults {
    self = [super initDefaults];

#ifdef ABLY_SUPPORTS_PLUGINS
    // The LiveObjects repository provides an extension to `ARTClientOptions` so we need to ensure that we register the pluginAPI before that extension is used.
    [ARTPluginAPI registerSelf];
#endif

    _endpoint = ARTDefaultEndpoint;
    _port = [ARTDefault port];
    _tlsPort = [ARTDefault tlsPort];
    _restHost = nil;
    _realtimeHost = nil;
    _environment = nil;
    _queueMessages = YES;
    _echoMessages = YES;
    _useBinaryProtocol = true;
    _autoConnect = true;
    _tls = YES;
    _logLevel = ARTLogLevelNone;
    _logHandler = [[ARTLog alloc] init];
    _disconnectedRetryTimeout = 15.0; //Seconds
    _suspendedRetryTimeout = 30.0; //Seconds
    _channelRetryTimeout = 15.0; //Seconds
    _httpOpenTimeout = 4.0; //Seconds
    _httpRequestTimeout = 10.0; //Seconds
    _fallbackRetryTimeout = 600.0; // Seconds, TO3l10
    _httpMaxRetryDuration = 15.0; //Seconds
    _httpMaxRetryCount = 3;
    _fallbackHosts = nil;
    _fallbackHostsUseDefault = false;
    _logExceptionReportingUrl = @"https://765e1fcaba404d7598d2fd5a2a43c4f0:8d469b2b0fb34c01a12ae217931c4aed@errors.ably.io/3";
    _dispatchQueue = dispatch_get_main_queue();
    _internalDispatchQueue = dispatch_queue_create("io.ably.main", DISPATCH_QUEUE_SERIAL);
    _pushFullWait = false;
    _idempotentRestPublishing = [ARTClientOptions getDefaultIdempotentRestPublishingForVersion:[ARTDefault apiVersion]];
    _addRequestIds = false;
    _pushRegistererDelegate = nil;
    _testOptions = [[ARTTestClientOptions alloc] init];
    _pluginData = [[NSMutableDictionary alloc] init];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@\n\t clientId: %@;", [super description], self.clientId];
}

// MARK: - Endpoint support

- (void)setEndpoint:(NSString *)endpoint {
    // REC1b1: endpoint cannot be used with deprecated options
    if (self.hasEnvironment || self.hasCustomRestHost || self.hasCustomRealtimeHost) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `endpoint` option cannot be used in conjunction with the `environment`, `restHost`, or `realtimeHost` options."];
    }
    _endpoint = endpoint;
}

- (NSString *)endpoint {
    return _endpoint;
}

- (BOOL)isEndpointFQDN {
    return [self.endpoint containsString:@"."] || [self.endpoint containsString:@"::"] || [self.endpoint isEqualToString:@"localhost"];
}

- (NSString *)primaryDomain {
    // Check for endpoint first (REC1b)
    if (self.endpoint && self.endpoint.isNotEmptyString) {
        if (self.isEndpointFQDN) {
            return self.endpoint; // REC1b2: endpoint is a valid hostname
        }
        
        if ([self.endpoint hasPrefix:@"nonprod:"]) {
            // REC1b3: endpoint in form "nonprod:[name]"
            NSString *routingPolicy = [self.endpoint substringFromIndex:8]; // Remove "nonprod:" prefix
            return [ARTDefault nonprodPrimaryDomainForRoutingPolicy:routingPolicy];
        }
        
        // REC1b4: endpoint in form "[name]"
        return [ARTDefault primaryDomainForRoutingPolicy:self.endpoint];
    }
    
    // Legacy environment handling (REC1c)
    if (self.hasEnvironment) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [ARTDefault primaryDomainForRoutingPolicy:self.environment];
#pragma clang diagnostic pop
    }
    
    // Legacy host override
    if (_restHost != nil) {
        return _restHost; // REC1d1
    }
    
    if (_realtimeHost != nil) {
        return _realtimeHost; // REC1d2
    }
    
    return ARTDefault.primaryDomain; // REC1a
}

- (NSArray<NSString *> *)fallbackDomains {
    // First check if explicit fallback hosts are provided
    if (self.fallbackHosts) { // REC2a2
        return self.fallbackHosts;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (self.fallbackHostsUseDefault) { // REC2b
        return ARTDefault.fallbackDomains; // REC2c1
    }
#pragma clang diagnostic pop
    
    // If the primary domain is default (REC2c1)
    if (self.hasDefaultPrimaryDomain) {
        return ARTDefault.fallbackDomains;
    }
    
    // If using endpoint, generate fallbacks based on the endpoint
    if (self.endpoint && [self.endpoint isNotEmptyString]) {
        if (self.isEndpointFQDN) {
            return @[]; // REC2c2: No fallbacks for FQDN/IP/localhost
        }
        
        if ([self.endpoint hasPrefix:@"nonprod:"]) {
            // REC2c3: nonprod routing policy
            NSString *routingPolicy = [self.endpoint substringFromIndex:8]; // Remove "nonprod:" prefix
            return [ARTDefault fallbackNonprodDomainsForRoutingPolicy:routingPolicy];
        }
        
        // REC2c4: production routing policy
        return [ARTDefault fallbackDomainsForRoutingPolicy:self.endpoint];
    }

    // REC2c5: legacy environment handling
    if (self.hasEnvironment) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [ARTDefault fallbackDomainsForRoutingPolicy:self.environment];
#pragma clang diagnostic pop
    }
    
    // REC2c6: legacy hosts handling
    if (self.hasCustomRestHost || self.hasCustomRealtimeHost) {
        return @[];
    }
    
    // Fallback to default value if nothing above triggered
    return ARTDefault.fallbackDomains;
}

// MARK: - Legacy hosts support

- (void)setEnvironment:(NSString *)environment {
    // REC1b1: endpoint cannot be used with deprecated options
    if (self.endpoint && [self.endpoint isNotEmptyString]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `endpoint` option cannot be used in conjunction with the `environment`, `restHost`, or `realtimeHost` options."];
    }
    
    // REC1c1: environment cannot be used with host options
    if (self.hasCustomRestHost || self.hasCustomRealtimeHost) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `environment` option cannot be used in conjunction with the `restHost`, or `realtimeHost` options."];
    }
    _environment = environment;
}

- (NSString *)environment {
    return _environment;
}

- (void)setRestHost:(NSString *)host {
    // REC1b1: endpoint cannot be used with deprecated options
    if (self.endpoint && [self.endpoint isNotEmptyString]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `endpoint` option cannot be used in conjunction with the `environment`, `restHost`, or `realtimeHost` options."];
    }
    
    // REC1c1: environment cannot be used with host options
    if (self.hasEnvironment) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `environment` option cannot be used in conjunction with the `restHost`, or `realtimeHost` options."];
    }
    _restHost = host;
}

- (NSString*)restHost {
    return _restHost;
}

- (void)setRealtimeHost:(NSString *)host {
    // REC1b1: endpoint cannot be used with deprecated options
    if (self.endpoint && [self.endpoint isNotEmptyString]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `endpoint` option cannot be used in conjunction with the `environment`, `restHost`, or `realtimeHost` options."];
    }
    
    // REC1c1: environment cannot be used with host options
    if (self.hasEnvironment) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The `environment` option cannot be used in conjunction with the `restHost`, or `realtimeHost` options."];
    }
    _realtimeHost = host;
}

- (NSString*)realtimeHost {
    return _realtimeHost;
}

- (NSURLComponents *)restUrlComponents {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"https" : @"http";
    components.host = self.primaryDomain;
    components.port = [NSNumber numberWithInteger:(self.tls ? self.tlsPort : self.port)];
    return components;
}

- (NSURL*)restUrl {
    return [self restUrlComponents].URL;
}

- (NSURL*)realtimeUrl {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"wss" : @"ws";
    components.host = self.primaryDomain;
    components.port = [NSNumber numberWithInteger:(self.tls ? self.tlsPort : self.port)];
    return components.URL;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTClientOptions *options = [super copyWithZone:zone];

    options.clientId = self.clientId;
    options.endpoint = self.endpoint;
    options.port = self.port;
    options.tlsPort = self.tlsPort;
    options.queueMessages = self.queueMessages;
    options.echoMessages = self.echoMessages;
    options.recover = self.recover;
    options.useBinaryProtocol = self.useBinaryProtocol;
    options.autoConnect = self.autoConnect;
    options.tls = self.tls;
    options.logLevel = self.logLevel;
    options.logHandler = self.logHandler;
    options.suspendedRetryTimeout = self.suspendedRetryTimeout;
    options.disconnectedRetryTimeout = self.disconnectedRetryTimeout;
    options.channelRetryTimeout = self.channelRetryTimeout;
    options.httpMaxRetryCount = self.httpMaxRetryCount;
    options.httpMaxRetryDuration = self.httpMaxRetryDuration;
    options.httpOpenTimeout = self.httpOpenTimeout;
    options.fallbackRetryTimeout = self.fallbackRetryTimeout;
    options->_fallbackHosts = self.fallbackHosts; //ignore setter
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    options->_fallbackHostsUseDefault = self.fallbackHostsUseDefault; //ignore setter
    if (self->_restHost) options.restHost = self.restHost;
    if (self->_realtimeHost) options.realtimeHost = self.realtimeHost;
    if (self->_environment) options.environment = self.environment;
#pragma clang diagnostic pop

    options.httpRequestTimeout = self.httpRequestTimeout;
    options.logExceptionReportingUrl = self.logExceptionReportingUrl;
    options.dispatchQueue = self.dispatchQueue;
    options.internalDispatchQueue = self.internalDispatchQueue;
    options.pushFullWait = self.pushFullWait;
    options.idempotentRestPublishing = self.idempotentRestPublishing;
    options.addRequestIds = self.addRequestIds;
    options.pushRegistererDelegate = self.pushRegistererDelegate;
    options.transportParams = self.transportParams;
    options.agents = self.agents;
    options.testOptions = self.testOptions;
    options.plugins = self.plugins;
    options.pluginData = [self.pluginData mutableCopy];

    return options;
}

- (BOOL)isBasicAuth {
    return self.useTokenAuth == false &&
        self.key != nil &&
        self.token == nil &&
        self.tokenDetails == nil &&
        self.authUrl == nil &&
        self.authCallback == nil;
}

- (BOOL)hasCustomPrimaryDomain {
    return self.endpoint != nil && ![self.endpoint isEqualToString:ARTDefault.primaryDomain];
}

- (BOOL)hasDefaultPrimaryDomain {
    return ![self hasCustomPrimaryDomain];
}

- (BOOL)hasCustomRestHost {
    return _restHost != nil;
}

- (BOOL)hasDefaultRestHost {
    return ![self hasCustomRestHost];
}

- (BOOL)hasCustomRealtimeHost {
    return _realtimeHost != nil;
}

- (BOOL)hasDefaultRealtimeHost {
    return ![self hasCustomRealtimeHost];
}

- (BOOL)hasCustomPort {
    return self.port && self.port != [ARTDefault port];
}

- (BOOL)hasCustomTlsPort {
    return self.tlsPort && self.tlsPort != [ARTDefault tlsPort];
}

- (void)setFallbackHosts:(nullable NSArray<NSString *> *)value {
    if (_fallbackHostsUseDefault) {
        [ARTException raise:ARTFallbackIncompatibleOptionsException format:@"Could not setup custom fallback hosts because it is currently configured to use default fallback hosts."];
    }
    _fallbackHosts = value;
}

- (void)setFallbackHostsUseDefault:(BOOL)value {
    if (_fallbackHosts) {
        [ARTException raise:ARTFallbackIncompatibleOptionsException format:@"Could not configure options to use default fallback hosts because a custom fallback host list is being used."];
    }
    _fallbackHostsUseDefault = value;
}

+ (void)setDefaultEndpoint:(NSString *)endpoint {
    ARTDefaultEndpoint = endpoint;
}

- (void)setDefaultTokenParams:(ARTTokenParams *)value {
    _defaultTokenParams = [[ARTTokenParams alloc] initWithTokenParams:value];
}

+ (BOOL)getDefaultIdempotentRestPublishingForVersion:(NSString *)version {
    if ([@"1.2" compare:version options:NSNumericSearch] == NSOrderedDescending) {
        return false;
    }
    else {
        return true;
    }
}

- (BOOL)isProductionEnvironment {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[self.environment lowercaseString] isEqualToString:[ARTDefaultProductionEnvironment lowercaseString]];
#pragma clang diagnostic pop
}

- (BOOL)hasEnvironment {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return self.environment != nil && [self.environment isNotEmptyString];
#pragma clang diagnostic pop
}

// MARK: - Plugins

#ifdef ABLY_SUPPORTS_PLUGINS
- (nullable id<APLiveObjectsInternalPluginProtocol>)liveObjectsPlugin {
    Class<APLiveObjectsPluginProtocol> publicPlugin = self.plugins[ARTPluginNameLiveObjects];

    if (!publicPlugin) {
        return nil;
    }

    return [publicPlugin internalPlugin];
}
#endif

// MARK: - Options for plugins

- (void)setPluginOptionsValue:(id)value forKey:(NSString *)key {
    self.pluginData[key] = value;
}

- (id)pluginOptionsValueForKey:(NSString *)key {
    return self.pluginData[key];
}

@end
