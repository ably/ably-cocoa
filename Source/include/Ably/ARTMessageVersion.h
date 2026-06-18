#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains version information for a message, including operation metadata.
 */
NS_SWIFT_SENDABLE
@interface ARTMessageVersion : NSObject

/// The serial of the message version.
@property (nullable, readonly, nonatomic) NSString *serial;

/// The timestamp of the message version.
@property (nullable, readonly, nonatomic) NSDate *timestamp;

/// The client ID associated with this version.
@property (nullable, readonly, nonatomic) NSString *clientId;

/// A description of the operation performed.
@property (nullable, readonly, nonatomic) NSString *descriptionText;

/// Metadata associated with the operation.
@property (nullable, readonly, nonatomic) NSDictionary<NSString *, NSString *> *metadata;

/**
 * Initializes an `ARTMessageVersion` with all properties.
 *
 * @param serial The serial of the message version.
 * @param timestamp The timestamp of the message version.
 * @param clientId The client ID associated with this version.
 * @param descriptionText A description of the operation performed.
 * @param metadata Metadata associated with the operation.
 */
- (instancetype)initWithSerial:(nullable NSString *)serial
                     timestamp:(nullable NSDate *)timestamp
                      clientId:(nullable NSString *)clientId
               descriptionText:(nullable NSString *)descriptionText
                      metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

@end

NS_ASSUME_NONNULL_END
