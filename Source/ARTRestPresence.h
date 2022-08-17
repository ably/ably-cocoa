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
 * Retrieves the current members present on the channel and the metadata for each member, such as their [`PresenceAction`]{@link PresenceAction} and ID. Returns a [`PaginatedResult`]{@link PaginatedResult} object, containing an array of [`PresenceMessage`]{@link PresenceMessage} objects.
 *
 * @param limit An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 * @param clientId Filters the list of returned presence members by a specific client using its ID.
 * @param connectionId Filters the list of returned presence members by a specific connection using its ID.
 *
 * @return A [`PaginatedResult`]{@link PaginatedResult} object containing an array of [`PresenceMessage`]{@link PresenceMessage} objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

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
