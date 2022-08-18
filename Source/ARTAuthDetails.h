#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the token string used to authenticate a client with Ably.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Used with an AUTH protocol messages to send authentication details
 * END LEGACY DOCSTRING
 */
@interface ARTAuthDetails : NSObject<NSCopying>

@property (nonatomic, copy) NSString *accessToken;

- (instancetype)initWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
