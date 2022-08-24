#import <Foundation/Foundation.h>

#import <Ably/ARTPresence.h>
#import <Ably/ARTDataQuery.h>

@class ARTRestChannel;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPresenceQuery : NSObject

@property (nonatomic, readwrite) NSUInteger limit;
@property (nullable, nonatomic, strong, readwrite) NSString *clientId;
@property (nullable, nonatomic, strong, readwrite) NSString *connectionId;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

@end

@protocol ARTRestPresenceProtocol

- (void)get:(ARTPaginatedPresenceCallback)callback;
- (BOOL)get:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns a `ARTPaginatedResult` object, containing an array of `ARTPresenceMessage` objects.
 *
 * @param limit An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 * @param clientId Filters the list of returned presence members by a specific client using its ID.
 * @param connectionId Filters the list of returned presence members by a specific connection using its ID.
 *
 * @return A `ARTPaginatedResult` object containing an array of `ARTPresenceMessage` objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTPresenceMessage` objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param start The time from which messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param end The time until messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param direction The order for which messages are returned in. Valid values are `backwards` which orders messages from most recent to oldest, or `forwards` which orders messages from oldest to most recent. The default is `backwards`.
 * @param limit An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 *
 * @return A `ARTPaginatedResult` object containing an array of `ARTPresenceMessage` objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables the retrieval of the current and historic presence set for a channel.
 * END CANONICAL DOCSTRING
 */
@interface ARTRestPresence : ARTPresence <ARTRestPresenceProtocol>

- (void)get:(ARTPaginatedPresenceCallback)callback;
- (BOOL)get:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;
- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

NS_ASSUME_NONNULL_END
