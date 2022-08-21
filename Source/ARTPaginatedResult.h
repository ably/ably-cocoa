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
@property (nonatomic, readonly) BOOL hasNext;
@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (void)first:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;
- (void)next:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
