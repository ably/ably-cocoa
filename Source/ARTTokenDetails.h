#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTAuthOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains an Ably Token and its associated metadata.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTTokenDetails is a type providing details of Ably token string and its associated metadata.
 * END LEGACY DOCSTRING
 */
@interface ARTTokenDetails : NSObject<NSCopying>

/**
 Token string.
 */
@property (nonatomic, readonly, copy) NSString *token;

/**
 Contains the expiry time in milliseconds.
 */
@property (nonatomic, readonly, strong, nullable) NSDate *expires;

/**
 Contains the time the token was issued in milliseconds.
 */
@property (nonatomic, readonly, strong, nullable) NSDate *issued;

/**
 Contains the capability JSON stringified.
 */
@property (nonatomic, readonly, copy, nullable) NSString *capability;

/**
 Contains the clientId assigned to the token if provided.
 */
@property (nonatomic, readonly, copy, nullable) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithToken:(NSString *)token;
- (instancetype)initWithToken:(NSString *)token expires:(nullable NSDate *)expires issued:(nullable  NSDate *)issued capability:(nullable  NSString *)capability clientId:(nullable NSString *)clientId;

+ (ARTTokenDetails *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)error;

@end

@interface ARTTokenDetails (ARTTokenDetailsCompatible) <ARTTokenDetailsCompatible>
@end

NS_ASSUME_NONNULL_END
