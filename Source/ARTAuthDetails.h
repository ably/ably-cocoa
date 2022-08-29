#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the token string used to authenticate a client with Ably.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTAuthDetails : NSObject<NSCopying>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The authentication token string.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, copy) NSString *accessToken;

- (instancetype)initWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
