#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the possible actions members in the presence set can emit.
 * END CANONICAL PROCESSED DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A member is not present in the channel.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTPresenceAbsent,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * When subscribing to presence events on a channel that already has members present, this event is emitted for every member already present on the channel before the subscribe listener was registered.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTPresencePresent,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A new member has entered the channel.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTPresenceEnter,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * A member who was present has now left the channel. This may be a result of an explicit request to leave or implicitly when detaching from the channel. Alternatively, if a member's connection is abruptly disconnected and they do not resume their connection within a minute, Ably treats this as a leave event as the client is no longer present.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTPresenceLeave,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * An already present member has updated their member data. Being notified of member data updates can be very useful, for example, it can be used to update the status of a user when they are typing a message.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTPresenceUpdate
};

NSString *_Nonnull ARTPresenceActionToStr(ARTPresenceAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains an individual presence update sent to, or received from, Ably.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTPresenceMessage : ARTBaseMessage

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The type of `ARTPresenceAction` the `ARTPresenceMessage` is for.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) ARTPresenceAction action;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Combines `clientId` and `connectionId` to ensure that multiple connected clients with an identical `clientId` are uniquely identifiable. A string function that returns the combined `clientId` and `connectionId`.
 *
 * @return A combination of `clientId` and `connectionId`.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (nonnull NSString *)memberKey;

- (BOOL)isEqualToPresenceMessage:(nonnull ARTPresenceMessage *)presence;

- (BOOL)isNewerThan:(ARTPresenceMessage *)latest __attribute__((warn_unused_result));

@end

#pragma mark - ARTEvent

/// :nodoc:
@interface ARTEvent (PresenceAction)
- (instancetype)initWithPresenceAction:(ARTPresenceAction)value;
+ (instancetype)newWithPresenceAction:(ARTPresenceAction)value;
@end

NS_ASSUME_NONNULL_END
