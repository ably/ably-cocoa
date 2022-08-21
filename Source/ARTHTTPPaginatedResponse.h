#import <Foundation/Foundation.h>

#import <Ably/ARTPaginatedResult.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * A superset of [`PaginatedResult`]{@link PaginatedResult} which represents a page of results plus metadata indicating the relative queries available to it. `HttpPaginatedResponse` additionally carries information about the response to an HTTP request.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTHTTPPaginatedResponse is a superset of ``ARTPaginatedResult``, which is a type that represents a page of results plus metadata indicating the relative queries available to it. ARTHTTPPaginatedResponse additionally carries information about the response to an HTTP request. It is used when making custom HTTP requests.
 * END LEGACY DOCSTRING
 */
@interface ARTHTTPPaginatedResponse : ARTPaginatedResult<NSDictionary *>

/**
 * BEGIN CANONICAL DOCSTRING
 * The HTTP status code of the response.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Return the HTTP status code of the response
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly) NSInteger statusCode;

/**
 * BEGIN CANONICAL DOCSTRING
 * Whether `statusCode` indicates success. This is equivalent to `200 <= statusCode < 300`.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Returns true when the HTTP status code indicates success i.e. 200 <= statusCode < 300
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly) BOOL success;

/**
 * BEGIN CANONICAL DOCSTRING
 * The error code if the `X-Ably-Errorcode` HTTP header is sent in the response.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Returns the error code if the X-Ably-ErrorCode HTTP header is sent in the response
 * END LEGACY DOCSTRING
 */
@property (nonatomic, readonly) NSInteger errorCode;

/// Returns error message if the X-Ably-ErrorMessage HTTP header is sent in the response
@property (nullable, nonatomic, readonly) NSString *errorMessage;

/// Returns a dictionary containing all the HTTP header fields of the response header.
@property (nonatomic, readonly) NSStringDictionary *headers;

- (void)first:(ARTHTTPPaginatedCallback)callback;
- (void)next:(ARTHTTPPaginatedCallback)callback;

@end

NS_ASSUME_NONNULL_END
