#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import "ARTStringifiable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains operation metadata for message updates.
 */
NS_SWIFT_SENDABLE
@interface ARTMessageOperation : NSObject

/// The client ID associated with this operation.
@property (nullable, readonly, nonatomic) NSString *clientId;

/// A description of the operation performed.
@property (nullable, readonly, nonatomic) NSString *descriptionText;

/// Metadata associated with the operation.
@property (nullable, readonly, nonatomic) NSDictionary<NSString *, NSString *> *metadata;

- (instancetype)initWithClientId:(nullable NSString *)clientId descriptionText:(nullable NSString *)descriptionText metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

@end

NS_ASSUME_NONNULL_END
