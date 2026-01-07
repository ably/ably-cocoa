#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The policy that the library will use to determine its REC1 primary domain and REC2 set of fallback domains.
 */
@interface ARTDomainSelector : NSObject

/**
 Initialize with all client options that affect domain selection.
 
 @param endpointClientOption The value of the `endpoint` client option.
 @param fallbackHostsClientOption The value of the `fallbackHosts` client option.
 @param environmentClientOption The value of the deprecated `environment` client option.
 @param restHostClientOption The value of the deprecated `restHost` client option.
 @param realtimeHostClientOption The value of the deprecated `realtimeHost` client option.
 @param fallbackHostsUseDefault The value of the deprecated `fallbackHostsUseDefault` client option.
 @return An initialized instance of ARTDomainSelector.
 */
- (instancetype)initWithEndpointClientOption:(nullable NSString *)endpointClientOption
                   fallbackHostsClientOption:(nullable NSArray<NSString *> *)fallbackHostsClientOption
                     environmentClientOption:(nullable NSString *)environmentClientOption
                        restHostClientOption:(nullable NSString *)restHostClientOption
                    realtimeHostClientOption:(nullable NSString *)realtimeHostClientOption
                     fallbackHostsUseDefault:(BOOL)fallbackHostsUseDefault;

/**
 Initialize with all client options with their defaults.
 */
- (instancetype)init;

/**
 The REC1 primary domain.
 */
@property (nonatomic, readonly) NSString *primaryDomain;

/**
 The set of fallback domains, as defined by REC2.
 */
@property (nonatomic, readonly) NSArray<NSString *> *fallbackDomains;

@end

NS_ASSUME_NONNULL_END
