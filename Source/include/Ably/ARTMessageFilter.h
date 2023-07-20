#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTMessageFilter : NSObject<NSCopying>

/**
 * Whether the message should contain a `extras.ref` field.
 * Spec: MFI2a
 */
@property (readwrite, nonatomic) bool isRef;

/**
 * Value to check against `extras.ref.timeserial`.`.
 * Spec: MFI2b
 */
@property (readwrite, nonatomic) NSString *refTimeserial;

/**
 * Value to check against `extras.ref.type`.`.
 * Spec: MFI2c
 */
@property (readwrite, nonatomic) NSString *refType;

/**
 * Value to check against the `name` of a message.
 * Spec: MFI2d
 */
@property (readwrite, nonatomic) NSString *name;

/**
 * Value to check against the `cliendId` that published the message.
 * Spec: MFI2e
 */
@property (readwrite, nonatomic) NSString *cliendId;

@end
