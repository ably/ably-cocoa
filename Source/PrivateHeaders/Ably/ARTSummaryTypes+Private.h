#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for summary types that can initialize from NSDictionary.
 * Similar to how ARTJsonLikeEncoder parses dictionaries.
 */
NS_SWIFT_SENDABLE
@protocol ARTDictionarySerializable <NSObject>

/**
 * Initializes the summary type from an NSDictionary.
 * @param dictionary The dictionary containing the summary data
 * @return An initialized instance or nil if parsing fails
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Creates a summary type instance from an NSDictionary.
 * @param dictionary The dictionary containing the summary data
 * @return A new instance or nil if parsing fails
 */
+ (nullable instancetype)createFromDictionary:(NSDictionary *)dictionary;

/**
 * Writes the summary type data to a mutable dictionary.
 * @param dictionary The dictionary to write to
 */
- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary;

@end

NS_ASSUME_NONNULL_END
