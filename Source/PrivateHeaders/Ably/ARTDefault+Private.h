#import <Ably/ARTDefault.h>

extern NSString *const ARTDefaultProductionEnvironment;

@interface ARTDefault (Private)

+ (void)setConnectionStateTtl:(NSTimeInterval)value;
+ (void)setMaxMessageSize:(NSInteger)value;

+ (NSInteger)maxSandboxMessageSize;
+ (NSInteger)maxProductionMessageSize;

+ (NSString *)primaryDomainForRoutingPolicy:(NSString *)routingPolicy;
+ (NSString *)nonprodPrimaryDomainForRoutingPolicy:(NSString *)routingPolicy;
+ (NSArray<NSString *> *)fallbackDomainsForRoutingPolicy:(NSString *)routingPolicy;
+ (NSArray<NSString *> *)fallbackNonprodDomainsForRoutingPolicy:(NSString *)routingPolicy;

+ (NSString *)connectivityCheckUrl;

@end
