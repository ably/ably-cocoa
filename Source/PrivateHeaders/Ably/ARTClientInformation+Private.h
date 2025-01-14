#import <Ably/ARTClientInformation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTClientInformation_libraryVersion;

@interface ARTClientInformation (Private)

+ (NSString *)libraryAgentIdentifier;
+ (NSString *)platformAgentIdentifier;

@end

NS_ASSUME_NONNULL_END
