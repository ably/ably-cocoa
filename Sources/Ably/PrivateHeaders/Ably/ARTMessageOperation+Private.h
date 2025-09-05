@import Foundation;
#import <Ably/ARTMessageOperation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTMessageOperation ()

// Serialize the Operation object
- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary;

// Deserialize an Operation object from a NSDictionary object
+ (instancetype)createFromDictionary:(NSDictionary<NSString *, id> *)jsonObject;

@end

NS_ASSUME_NONNULL_END
