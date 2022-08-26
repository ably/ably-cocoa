#import <Foundation/Foundation.h>

#import <Ably/ARTPresence.h>
#import <Ably/ARTDataQuery.h>

@class ARTRestChannel;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPresenceQuery : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, readwrite) NSUInteger limit;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Filters the array of returned presence members by a specific client using its ID.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, nonatomic, strong, readwrite) NSString *clientId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Filters the array of returned presence members by a specific connection using its ID.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, nonatomic, strong, readwrite) NSString *connectionId;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

@end

@protocol ARTRestPresenceProtocol

- (void)get:(ARTPaginatedPresenceCallback)callback;
- (BOOL)get:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns a `ARTPaginatedResult` object, containing an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTPresenceQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTPresenceMessage` objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param query An `ARTDataQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables the retrieval of the current and historic presence set for a channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTRestPresence : ARTPresence <ARTRestPresenceProtocol>

- (void)get:(ARTPaginatedPresenceCallback)callback;
- (BOOL)get:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;
- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

NS_ASSUME_NONNULL_END
