#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains a page of results for message or presence history, stats, or REST presence requests. An `ARTPaginatedResult` response from a REST API paginated query is also accompanied by metadata that indicates the relative queries available to the `ARTPaginatedResult` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTPaginatedResult<ItemType> : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the current page of results; for example, an array of `ARTMessage` or `ARTPresenceMessage` objects for a channel history request.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, readonly) NSArray<ItemType> *items;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Returns `true` if there are more pages available by calling next and returns `false` if this page is the last page available.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) BOOL hasNext;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Returns `true` if this page is the last page and returns `false` if there are more pages available by calling next available.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Returns a new `ARTPaginatedResult` for the first page of results.
 *
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ItemType` objects.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)first:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Returns a new `ARTPaginatedResult` loaded with the next page of results. If there are no further pages, then `nil` is returned.
 *
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ItemType` objects.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)next:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
