#import <Foundation/Foundation.h>

#import <Ably/ARTPresence.h>
#import <Ably/ARTDataQuery.h>

@class ARTRestChannel;

NS_ASSUME_NONNULL_BEGIN

/**
 This object is used for providing parameters into `ARTRestPresence`'s methods with paginated results.
 */
@interface ARTPresenceQuery : NSObject

/**
 * An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 */
@property (nonatomic, readwrite) NSUInteger limit;

/**
 * Filters the array of returned presence members by a specific client using its ID.
 */
@property (nullable, nonatomic, strong, readwrite) NSString *clientId;

/**
 * Filters the array of returned presence members by a specific connection using its ID.
 */
@property (nullable, nonatomic, strong, readwrite) NSString *connectionId;

/// :nodoc:
- (instancetype)init;

/// :nodoc:
- (instancetype)initWithClientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

/// :nodoc:
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

@end

/**
 The protocol upon which the `ARTRestPresence` is implemented.
 */
@protocol ARTRestPresenceProtocol

/// :nodoc: TODO: docstring
- (void)get:(ARTPaginatedPresenceCallback)callback;

/// :nodoc: TODO: docstring
- (BOOL)get:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns a `ARTPaginatedResult` object, containing an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTPresenceQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
 */
- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTPresenceMessage` objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param query An `ARTDataQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
 */
- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

/**
 * Enables the retrieval of the current and historic presence set for a channel.
 *
 * @see See `ARTRestPresenceProtocol` for details.
 */
@interface ARTRestPresence : ARTPresence <ARTRestPresenceProtocol>
@end

NS_ASSUME_NONNULL_END
