#import <Foundation/Foundation.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the details of the push registration of a device.
 * END CANONICAL DOCSTRING
 */
@interface ARTDevicePushDetails : NSObject

/**
 * BEGIN CANONICAL DOCSTRING
 * A JSON object of key-value pairs that contains of the push transport and address.
 * END CANONICAL DOCSTRING
 */
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *recipient;

/**
 * BEGIN CANONICAL DOCSTRING
 * The current state of the push registration.
 * END CANONICAL DOCSTRING
 */
@property (strong, nullable, nonatomic) NSString *state;

/**
 * BEGIN CANONICAL DOCSTRING
 * An `ARTErrorInfo` object describing the most recent error when the `state` is `Failing` or `Failed`.
 * END CANONICAL DOCSTRING
 */
@property (strong, nullable, nonatomic) ARTErrorInfo *errorReason;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
