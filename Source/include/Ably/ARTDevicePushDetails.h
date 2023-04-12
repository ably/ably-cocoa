#import <Foundation/Foundation.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains the details of the push registration of a device.
 */
@interface ARTDevicePushDetails : NSObject

/**
 * A JSON object of key-value pairs that contains of the push transport and address.
 */
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *recipient;

/**
 * The current state of the push registration.
 */
@property (nullable, nonatomic) NSString *state;

/**
 * An `ARTErrorInfo` object describing the most recent error when the `state` is `Failing` or `Failed`.
 */
@property (nullable, nonatomic) ARTErrorInfo *errorReason;

/// :nodoc:
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
