#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains annotations summary for a message. The keys of the dict are annotation types, and the values are aggregated summaries for that annotation type.
 */
NS_SWIFT_SENDABLE
@interface ARTMessageAnnotations : NSObject

/// An annotations summary for the message. The keys of the dict are annotation types, and the values are aggregated summaries for that annotation type.
@property (nonatomic, readonly, nullable) ARTJsonObject *summary;

/**
 * Initializes an `ARTMessageAnnotations` with all properties.
 *
 * @param summary An annotations summary for the message. The keys of the dict are annotation types, and the values are aggregated summaries for that annotation type.
 */
- (instancetype)initWithSummary:(nullable ARTJsonObject *)summary;

@end

NS_ASSUME_NONNULL_END
