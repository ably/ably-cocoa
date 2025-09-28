#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import "ARTMessageAnnotations.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for summary types that can initialize from NSDictionary.
 * Similar to how ARTJsonLikeEncoder parses dictionaries.
 */
NS_SWIFT_SENDABLE
@protocol ARTDictionarySerializable <NSObject>

/**
 * Initializes the summary type from an NSDictionary.
 * @param dictionary The dictionary containing the summary data
 * @return An initialized instance or nil if parsing fails
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Creates a summary type instance from an NSDictionary.
 * @param dictionary The dictionary containing the summary data
 * @return A new instance or nil if parsing fails
 */
+ (nullable instancetype)createFromDictionary:(NSDictionary *)dictionary;

/**
 * Writes the summary type data to a mutable dictionary.
 * @param dictionary The dictionary to write to
 */
- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary;

@end

/**
 * TM7c1: Summary with total count and list of client IDs.
 */
NS_SWIFT_SENDABLE
@interface ARTSummaryClientIdList : NSObject <ARTDictionarySerializable>

/// Total count of items
@property (nonatomic, readonly) NSInteger total;

/// Array of client IDs
@property (nonatomic, readonly, copy) NSArray<NSString *> *clientIds;

/// Whether the summary data is clipped (truncated)
@property (nonatomic, readonly) BOOL clipped;

/**
 * Initializes with total count and client IDs array.
 * @param total The total count
 * @param clientIds Array of client ID strings
 */
- (instancetype)initWithTotal:(NSInteger)total clientIds:(NSArray<NSString *> *)clientIds;

/**
 * Initializes with all properties.
 * @param total The total count
 * @param clientIds Array of client ID strings
 * @param clipped Whether the data is clipped
 */
- (instancetype)initWithTotal:(NSInteger)total 
                    clientIds:(NSArray<NSString *> *)clientIds
                      clipped:(BOOL)clipped;

@end

/**
 * TM7d1: Summary with total count and dictionary mapping client IDs to counts.
 */
NS_SWIFT_SENDABLE
@interface ARTSummaryClientIdCounts : NSObject <ARTDictionarySerializable>

/// Total count of items
@property (nonatomic, readonly) NSInteger total;

/// Dictionary mapping client IDs to their counts
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> *clientIds;

/// Whether the summary data is clipped (truncated)
@property (nonatomic, readonly) BOOL clipped;

/// Total number of unidentified annotations
@property (nonatomic, readonly) NSInteger totalUnidentified;

/// Total number of unique client IDs
@property (nonatomic, readonly) NSInteger totalClientIds;

/**
 * Initializes with total count and client ID counts dictionary.
 * @param total The total count
 * @param clientIds Dictionary mapping client IDs to their counts
 */
- (instancetype)initWithTotal:(NSInteger)total clientIds:(NSDictionary<NSString *, NSNumber *> *)clientIds;

/**
 * Initializes with all properties.
 * @param total The total count
 * @param clientIds Dictionary mapping client IDs to their counts
 * @param clipped Whether the data is clipped
 * @param totalUnidentified Total unidentified annotations
 * @param totalClientIds Total unique client IDs
 */
- (instancetype)initWithTotal:(NSInteger)total 
                    clientIds:(NSDictionary<NSString *, NSNumber *> *)clientIds
                      clipped:(BOOL)clipped
            totalUnidentified:(NSInteger)totalUnidentified
               totalClientIds:(NSInteger)totalClientIds;

@end

/**
 * TM7e1: Summary with only total count.
 */
NS_SWIFT_SENDABLE
@interface ARTSummaryTotal : NSObject <ARTDictionarySerializable>

/// Total count of items
@property (nonatomic, readonly) NSInteger total;

/**
 * Initializes with total count.
 * @param total The total count
 */
- (instancetype)initWithTotal:(NSInteger)total;

@end

// Global functions for parsing summary dictionaries (TM7b).

/**
 * A static method that takes the value of one of the keys in the `Message.annotations.summary` object for the `distinct.v1` annotation type, and outputs a strongly-typed summary entry.
 * @param dictionary The value of one of the keys of the `Message.annotations.summary`.
 * @return Map of annotation name to aggregated annotations.
 */
NSDictionary<NSString *, ARTSummaryClientIdList *> * _Nullable ARTSummaryDistinctV1(NSDictionary * _Nullable dictionary);

/**
 * A static method that takes the value of one of the keys in the `Message.annotations.summary` object for the `unique.v1` annotation type, and outputs a strongly-typed summary entry.
 * @param dictionary The value of one of the keys of the `Message.annotations.summary`.
 * @return Map of annotation name to aggregated annotations.
 */
NSDictionary<NSString *, ARTSummaryClientIdList *> * _Nullable ARTSummaryUniqueV1(NSDictionary * _Nullable dictionary);

/**
 * A static method that takes the value of one of the keys in the `Message.annotations.summary` object for the `multiple.v1` annotation type, and outputs a strongly-typed summary entry.
 * @param dictionary The value of one of the keys of the `Message.summary`.
 * @return Map of annotation name to aggregated annotations.
 */
NSDictionary<NSString *, ARTSummaryClientIdCounts *> * _Nullable ARTSummaryMultipleV1(NSDictionary * _Nullable dictionary);

/**
 * A static factory method that takes the value of one of the keys in the `Message.annotations.summary` object for the `flag.v1` annotation type, and outputs a strongly-typed summary entry.
 * @param dictionary The value of one of the keys of the `Message.summary`.
 * @return Aggregated annotations.
 */
ARTSummaryClientIdList * _Nullable ARTSummaryFlagV1(NSDictionary * _Nullable dictionary);

/**
 * A static factory method that takes the value of one of the keys in the `Message.annotations.summary` object for the `total.v1` annotation type, and outputs a strongly-typed summary entry.
 * @param dictionary The value of one of the keys of the `Message.summary`.
 * @return Aggregated total summary.
 */
ARTSummaryTotal * _Nullable ARTSummaryTotalV1(NSDictionary * _Nullable dictionary);


/**
 * Convinience extension for `ARTMessageAnnotations` to convert summary raw object to the specific types (reactions only).
 */
@interface ARTMessageAnnotations (SummaryTypes)
/**
 * Converts the summary for the "reaction:distinct.v1" key to the dictionary of `ARTSummaryClientIdList`.
 * @return Dictionary of `ARTSummaryClientIdList` or nil if conversion fails.
 */
- (nullable NSDictionary<NSString *, ARTSummaryClientIdList *> *)summaryDistinctV1;

/**
 * Converts the summary for the "reaction:unique.v1" key to the dictionary of `ARTSummaryClientIdList`.
 * @return Dictionary of `ARTSummaryClientIdList` or nil if conversion fails.
 */
- (nullable NSDictionary<NSString *, ARTSummaryClientIdList *> *)summaryUniqueV1;

/**
 * Converts the summary for the "reaction:multiple.v1" key to the dictionary of `ARTSummaryClientIdCounts`.
 * @return Dictionary of `ARTSummaryClientIdCounts` or nil if conversion fails.
 */
- (nullable NSDictionary<NSString *, ARTSummaryClientIdCounts *> *)summaryMultipleV1;

@end

NS_ASSUME_NONNULL_END
