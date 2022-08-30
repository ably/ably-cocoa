#import <Foundation/Foundation.h>

#import <Ably/ARTPaginatedResult.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A superset of `ARTPaginatedResult` which represents a page of results plus metadata indicating the relative queries available to it. `ARTHttpPaginatedResponse` additionally carries information about the response to an HTTP request.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTHTTPPaginatedResponse : ARTPaginatedResult<NSDictionary *>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The HTTP status code of the response.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger statusCode;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Whether `statusCode` indicates success. This is equivalent to `200 <= statusCode < 300`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) BOOL success;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The error code if the `x-ably-errorcode` HTTP header is sent in the response.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSInteger errorCode;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The error message if the `x-ably-errormessage` HTTP header is sent in the response.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, nonatomic, readonly) NSString *errorMessage;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The headers of the response.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) NSStringDictionary *headers;

- (void)first:(ARTHTTPPaginatedCallback)callback;
- (void)next:(ARTHTTPPaginatedCallback)callback;

@end

NS_ASSUME_NONNULL_END
