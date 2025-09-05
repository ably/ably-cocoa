#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An interface outlining the optional `ARTMessageOperation` object which resides in an `ARTMessage` object. This is populated within the `ARTMessage` object when the message is an update or delete operation.
 */
@interface ARTMessageOperation : NSObject

@property (nonatomic, strong, nullable) NSString *clientId;
@property (nonatomic, strong, nullable) NSString *descriptionText;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *metadata;

@end
NS_ASSUME_NONNULL_END
