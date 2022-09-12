#import <Foundation/Foundation.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the details of the push registration of a device.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTDevicePushDetails : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A JSON object of key-value pairs that contains of the push transport and address.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *recipient;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The current state of the push registration.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nullable, nonatomic) NSString *state;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An `ARTErrorInfo` object describing the most recent error when the `state` is `Failing` or `Failed`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nullable, nonatomic) ARTErrorInfo *errorReason;

/// :nodoc:
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
