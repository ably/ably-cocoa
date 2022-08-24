#import <Foundation/Foundation.h>

#import <Ably/ARTPaginatedResult.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * A superset of [`PaginatedResult`]{@link PaginatedResult} which represents a page of results plus metadata indicating the relative queries available to it. `HttpPaginatedResponse` additionally carries information about the response to an HTTP request.
 * END CANONICAL DOCSTRING
 */
@interface ARTHTTPPaginatedResponse : ARTPaginatedResult<NSDictionary *>

/**
 * BEGIN CANONICAL DOCSTRING
 * The HTTP status code of the response.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) NSInteger statusCode;

/**
 * BEGIN CANONICAL DOCSTRING
 * Whether `statusCode` indicates success. This is equivalent to `200 <= statusCode < 300`.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) BOOL success;

/**
 * BEGIN CANONICAL DOCSTRING
 * The error code if the `X-Ably-Errorcode` HTTP header is sent in the response.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) NSInteger errorCode;

/**
 * BEGIN CANONICAL DOCSTRING
 * The error message if the `X-Ably-Errormessage` HTTP header is sent in the response.
 * END CANONICAL DOCSTRING
 */
@property (nullable, nonatomic, readonly) NSString *errorMessage;

/**
 * BEGIN CANONICAL DOCSTRING
 * The headers of the response.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) NSStringDictionary *headers;

- (void)first:(ARTHTTPPaginatedCallback)callback;
- (void)next:(ARTHTTPPaginatedCallback)callback;

@end

NS_ASSUME_NONNULL_END
