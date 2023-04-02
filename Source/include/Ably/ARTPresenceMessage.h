#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>

/**
 * Describes the possible actions members in the presence set can emit.
 */
typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    /**
         * A member is not present in the channel.
         */
    ARTPresenceAbsent,
    /**
         * When subscribing to presence events on a channel that already has members present, this event is emitted for every member already present on the channel before the subscribe listener was registered.
         */
    ARTPresencePresent,
    /**
         * A new member has entered the channel.
         */
    ARTPresenceEnter,
    /**
         * A member who was present has now left the channel. This may be a result of an explicit request to leave or implicitly when detaching from the channel. Alternatively, if a member's connection is abruptly disconnected and they do not resume their connection within a minute, Ably treats this as a leave event as the client is no longer present.
         */
    ARTPresenceLeave,
    /**
         * An already present member has updated their member data. Being notified of member data updates can be very useful, for example, it can be used to update the status of a user when they are typing a message.
         */
    ARTPresenceUpdate
};

/// :nodoc:
NSString *_Nonnull ARTPresenceActionToStr(ARTPresenceAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains an individual presence update sent to, or received from, Ably.
 */
@interface ARTPresenceMessage : ARTBaseMessage

/**
 * The type of `ARTPresenceAction` the `ARTPresenceMessage` is for.
 */
@property (readwrite, assign, nonatomic) ARTPresenceAction action;

/**
 * Combines `ARTBaseMessage.clientId` and `ARTBaseMessage.connectionId` to ensure that multiple connected clients with an identical `clientId` are uniquely identifiable.
 *
 * @return A combination of `ARTBaseMessage.clientId` and `ARTBaseMessage.connectionId`.
 */
- (nonnull NSString *)memberKey;

/// :nodoc:
- (BOOL)isEqualToPresenceMessage:(nonnull ARTPresenceMessage *)presence;

/// :nodoc:
- (BOOL)isNewerThan:(ARTPresenceMessage *)latest __attribute__((warn_unused_result));

@end

#pragma mark - ARTEvent

/// :nodoc:
@interface ARTEvent (PresenceAction)
- (instancetype)initWithPresenceAction:(ARTPresenceAction)value;
+ (instancetype)newWithPresenceAction:(ARTPresenceAction)value;
@end

NS_ASSUME_NONNULL_END
