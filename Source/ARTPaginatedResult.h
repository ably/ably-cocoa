#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains a page of results for message or presence history, stats, or REST presence requests. A `PaginatedResult` response from a REST API paginated query is also accompanied by metadata that indicates the relative queries available to the `PaginatedResult` object.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTPaginatedResult is a type that represents a page of results for all message and presence history, stats and REST presence requests. The response from a Ably REST API paginated query is accompanied by metadata that indicates the relative queries available to the ARTPaginatedResult object.
 * END LEGACY DOCSTRING
 */
@interface ARTPaginatedResult<ItemType> : NSObject

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the current page of results; for example, an array of [`Message`]{@link Message} or [`PresenceMessage`]{@link PresenceMessage} objects for a channel history request.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, strong, readonly) NSArray<ItemType> *items;

/**
 * BEGIN CANONICAL DOCSTRING
 * Returns `true` if there are more pages available by calling next and returns `false` if this page is the last page available.
 *
 * @return Whether or not there are more pages of results.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) BOOL hasNext;

/**
 * BEGIN CANONICAL DOCSTRING
 * Returns `true` if this page is the last page and returns `false` if there are more pages available by calling next available.
 *
 * @return Whether or not this is the last page of results.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Returns a new `PaginatedResult` for the first page of results.
 *
 * @return A page of results for message and presence history, stats, and REST presence requests.
 * END CANONICAL DOCSTRING
 */
- (void)first:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Returns a new `PaginatedResult` loaded with the next page of results. If there are no further pages, then `null` is returned.
 *
 * @return A page of results for message and presence history, stats, and REST presence requests.
 * END CANONICAL DOCSTRING
 */
- (void)next:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
