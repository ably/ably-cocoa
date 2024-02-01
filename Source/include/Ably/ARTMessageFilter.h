#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTMessageFilter : NSObject<NSCopying>

/**
 * Whether the message should contain a `extras.ref` field.
 * Spec: MFI2a
 */
@property (readwrite, nonatomic, nullable) NSNumber* isRef;

/**
 * Value to check against `extras.ref.timeserial`.`.
 * Spec: MFI2b
 */
@property (readwrite, nonatomic, nullable) NSString *refTimeserial;

/**
 * Value to check against `extras.ref.type`.`.
 * Spec: MFI2c
 */
@property (readwrite, nonatomic, nullable) NSString *refType;

/**
 * Value to check against the `name` of a message.
 * Spec: MFI2d
 */
@property (readwrite, nonatomic, nullable) NSString *name;

/**
 * Value to check against the `clientId` that published the message.
 * Spec: MFI2e
 */
@property (readwrite, nonatomic, nullable) NSString *clientId;

// nodoc
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
