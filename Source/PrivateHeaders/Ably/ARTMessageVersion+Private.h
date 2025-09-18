@import Foundation;
#import <Ably/ARTMessageVersion.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTMessageVersion ()

// Serialize the MessageVersion object
- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary;

// Deserialize a MessageVersion object from a NSDictionary object
+ (instancetype)createFromDictionary:(NSDictionary<NSString *, id> *)jsonObject;

@end

NS_ASSUME_NONNULL_END
