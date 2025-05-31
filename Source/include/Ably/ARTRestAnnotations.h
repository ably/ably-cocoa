#import <Foundation/Foundation.h>

#import <Ably/ARTPresence.h>
#import <Ably/ARTDataQuery.h>

@class ARTRestChannel;

NS_ASSUME_NONNULL_BEGIN

/**
 This object is used for providing parameters into `ARTRestAnnotations`'s methods with paginated results.
 */
@interface ARTAnnotationsQuery : NSObject

/**
 * An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 */
@property (nonatomic, readwrite) NSUInteger limit;

/**
 * Filters the array of returned presence members by a specific client using its ID.
 */
@property (nullable, nonatomic, readwrite) NSString *clientId;

/**
 * Filters the array of returned presence members by a specific connection using its ID.
 */
@property (nullable, nonatomic, readwrite) NSString *connectionId;

/// :nodoc:
- (instancetype)init;

/// :nodoc:
- (instancetype)initWithClientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

/// :nodoc:
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

@end

/**
 The protocol upon which the `ARTRestAnnotations` is implemented.
 */
@protocol ARTRestAnnotationsProtocol

/**
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceAction.ARTPresenceEnter` event. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param annotation The payload to update for the presence member.
 * @param callback A success or failure callback function.
 */
- (void)publish:(ARTAnnotation *)annotation callback:(nullable ARTAnnotationErrorCallback)callback;

/**
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceAction.ARTPresenceEnter` event. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param annotation The payload to update for the presence member.
 * @param callback A success or failure callback function.
 */
- (void)unpublish:(ARTAnnotation *)annotation callback:(nullable ARTAnnotationErrorCallback)callback;

/**
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTRealtimeAnnotationsQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 */
- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback;

/**
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTRealtimeAnnotationsQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 */
- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback;

@end

/**
 * Enables the retrieval of the current and historic presence set for a channel.
 *
 * @see See `ARTRestAnnotationsProtocol` for details.
 */
NS_SWIFT_SENDABLE
@interface ARTRestAnnotations : NSObject <ARTRestAnnotationsProtocol>
@end

NS_ASSUME_NONNULL_END
