#import <Foundation/Foundation.h>

#import <Ably/ARTPaginatedResult.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTHTTPPaginatedResponse : ARTPaginatedResult<NSDictionary *>

/// Return the HTTP status code of the response
@property (nonatomic, readonly) NSInteger statusCode;

/// Returns true when the HTTP status code indicates success i.e. 200 <= statusCode < 300
@property (nonatomic, readonly) BOOL success;

/// Returns the error code if the X-Ably-ErrorCode HTTP header is sent in the response
@property (nonatomic, readonly) NSInteger errorCode;

/// Returns error message if the X-Ably-ErrorMessage HTTP header is sent in the response
@property (nullable, nonatomic, readonly) NSString *errorMessage;

/// Returns a dictionary containing all the HTTP header fields of the response header.
@property (nonatomic, readonly) NSStringDictionary *headers;

- (void)first:(ARTHTTPPaginatedCallback)callback;
- (void)next:(ARTHTTPPaginatedCallback)callback;

@end

NS_ASSUME_NONNULL_END
