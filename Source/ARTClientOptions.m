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
#import "ARTDomainSelector.h"

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
    ARTDomainSelector *_domainSelector;
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
    _connectivityCheckUrl = [ARTDefault connectivityCheckUrl];
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
    // Reset domain selector when endpoint changes
    _domainSelector = nil;
}

- (NSString *)endpoint {
    return _endpoint;
}

- (ARTDomainSelector *)domainSelector {
    if (!_domainSelector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _domainSelector = [[ARTDomainSelector alloc] initWithEndpointClientOption:_endpoint
                                                        fallbackHostsClientOption:_fallbackHosts
                                                          environmentClientOption:_environment
                                                             restHostClientOption:_restHost
                                                         realtimeHostClientOption:_realtimeHost
                                                          fallbackHostsUseDefault:_fallbackHostsUseDefault];
#pragma clang diagnostic pop
    }
    return _domainSelector;
}

- (NSString *)primaryDomain {
    return self.domainSelector.primaryDomain;
}

- (NSArray<NSString *> *)fallbackDomains {
    return self.domainSelector.fallbackDomains;
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
    // Reset domain selector when environment changes
    _domainSelector = nil;
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
    // Reset domain selector when restHost changes
    _domainSelector = nil;
}

- (NSString *)restHost {
    return _restHost ?: self.domainSelector.primaryDomain;
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
    // Reset domain selector when realtimeHost changes
    _domainSelector = nil;
}

- (NSString *)realtimeHost {
    return _realtimeHost ?: self.domainSelector.primaryDomain;
}

- (NSURLComponents *)restUrlComponents {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"https" : @"http";
    components.host = self.primaryDomain;
    components.port = [NSNumber numberWithInteger:(self.tls ? self.tlsPort : self.port)];
    return components;
}

- (NSURL *)restUrl {
    return [self restUrlComponents].URL;
}

- (NSURL*)realtimeUrlForHost:(NSString *)host {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"wss" : @"ws";
    components.host = host;
    components.port = [NSNumber numberWithInteger:(self.tls ? self.tlsPort : self.port)];
    return components.URL;
}

- (NSURL*)realtimeUrl {
    return [self realtimeUrlForHost:self.primaryDomain];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTClientOptions *options = [super copyWithZone:zone];

    options.clientId = self.clientId;
    options->_endpoint = self.endpoint; //ignore setter
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
    options.connectivityCheckUrl = self.connectivityCheckUrl;
    options->_fallbackHosts = self.fallbackHosts; //ignore setter
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    options->_fallbackHostsUseDefault = self.fallbackHostsUseDefault; //ignore setter
    if (self->_restHost) options->_restHost = self.restHost; //ignore setter
    if (self->_realtimeHost) options->_realtimeHost = self.realtimeHost; //ignore setter
    if (self->_environment) options->_environment = self.environment; //ignore setter
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

- (BOOL)hasCustomRestHost {
    return _restHost != nil;
}

- (BOOL)hasCustomRealtimeHost {
    return _realtimeHost != nil;
}

- (void)setFallbackHosts:(nullable NSArray<NSString *> *)value {
    if (_fallbackHostsUseDefault) {
        [ARTException raise:ARTFallbackIncompatibleOptionsException format:@"Could not setup custom fallback hosts because it is currently configured to use default fallback hosts."];
    }
    _fallbackHosts = value;
    // Reset domain selector when fallbackHosts changes
    _domainSelector = nil;
}

- (void)setFallbackHostsUseDefault:(BOOL)value {
    if (_fallbackHosts) {
        [ARTException raise:ARTFallbackIncompatibleOptionsException format:@"Could not configure options to use default fallback hosts because a custom fallback host list is being used."];
    }
    _fallbackHostsUseDefault = value;
    // Reset domain selector when fallbackHostsUseDefault changes
    _domainSelector = nil;
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
