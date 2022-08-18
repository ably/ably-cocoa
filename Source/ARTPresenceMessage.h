#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>

/**
 * BEGIN CANONICAL DOCSTRING
 * Describes the possible actions members in the presence set can emit.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTPresenceAction represents all actions an ``ARTPresenceMessage`` can indicate.
 * END LEGACY DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    /**
     * BEGIN CANONICAL DOCSTRING
     * A member is not present in the channel.
     * END CANONICAL DOCSTRING
     */
    ARTPresenceAbsent,
    /**
     * BEGIN CANONICAL DOCSTRING
     * When subscribing to presence events on a channel that already has members present, this event is emitted for every member already present on the channel before the subscribe listener was registered.
     * END CANONICAL DOCSTRING
     */
    ARTPresencePresent,
    /**
     * BEGIN CANONICAL DOCSTRING
     * A new member has entered the channel.
     * END CANONICAL DOCSTRING
     */
    ARTPresenceEnter,
    /**
     * BEGIN CANONICAL DOCSTRING
     * A member who was present has now left the channel. This may be a result of an explicit request to leave or implicitly when detaching from the channel. Alternatively, if a member's connection is abruptly disconnected and they do not resume their connection within a minute, Ably treats this as a leave event as the client is no longer present.
     * END CANONICAL DOCSTRING
     */
    ARTPresenceLeave,
    /**
     * BEGIN CANONICAL DOCSTRING
     * An already present member has updated their member data. Being notified of member data updates can be very useful, for example, it can be used to update the status of a user when they are typing a message.
     * END CANONICAL DOCSTRING
     */
    ARTPresenceUpdate
};

NSString *_Nonnull ARTPresenceActionToStr(ARTPresenceAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains an individual presence update sent to, or received from, Ably.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTPresenceMessage represents an individual presence update that is sent to or received from Ably.
 * END LEGACY DOCSTRING
 */
@interface ARTPresenceMessage : ARTBaseMessage

/**
 * BEGIN CANONICAL DOCSTRING
 * The type of [`PresenceAction`]{@link PresenceAction} the `PresenceMessage` is for.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, assign, nonatomic) ARTPresenceAction action;

/**
 * BEGIN CANONICAL DOCSTRING
 * Combines `clientId` and `connectionId` to ensure that multiple connected clients with an identical `clientId` are uniquely identifiable. A string function that returns the combined `clientId` and `connectionId`.
 *
 * @return A combination of `clientId` and `connectionId`.
 * END CANONICAL DOCSTRING
 */
- (nonnull NSString *)memberKey;

- (BOOL)isEqualToPresenceMessage:(nonnull ARTPresenceMessage *)presence;

- (BOOL)isNewerThan:(ARTPresenceMessage *)latest __attribute__((warn_unused_result));

@end

#pragma mark - ARTEvent

@interface ARTEvent (PresenceAction)
- (instancetype)initWithPresenceAction:(ARTPresenceAction)value;
+ (instancetype)newWithPresenceAction:(ARTPresenceAction)value;
@end

NS_ASSUME_NONNULL_END
