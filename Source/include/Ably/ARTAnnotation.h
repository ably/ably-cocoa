#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>

/**
 * Describes the possible actions members in the presence set can emit.
 */
NS_SWIFT_SENDABLE
typedef NS_ENUM(NSUInteger, ARTAnnotationAction) {
    /**
     * A member is not present in the channel.
     */
    ARTAnnotationCreate,
    /**
     * When subscribing to presence events on a channel that already has members present, this event is emitted for every member already present on the channel before the subscribe listener was registered.
     */
    ARTAnnotationDelete,
};

/// :nodoc:
NSString *_Nonnull ARTAnnotationActionToStr(ARTAnnotationAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains an individual presence update sent to, or received from, Ably.
 */
@interface ARTAnnotation : ARTBaseMessage

/// The action type of the message, one of the `ARTMessageAction` enum values.
@property (readwrite, nonatomic) ARTAnnotationAction action;

/// This message's unique serial (an identifier that will be the same in all future updates of this message).
@property (nullable, readwrite, nonatomic) NSString *serial;

/// The serial of the operation that updated this message.
@property (nullable, readwrite, nonatomic) NSString *messageSerial;

/// The event name, if available
@property (nullable, readwrite, nonatomic) NSString *type;

/// The serial of the operation that updated this message.
@property (nullable, readwrite, nonatomic) NSString *name;

/// The action type of the message, one of the `ARTMessageAction` enum values.
@property (nullable, readwrite, nonatomic) NSNumber *count;

@end

#pragma mark - ARTEvent

/// :nodoc:
@interface ARTEvent (AnnotationAction)
- (instancetype)initWithAnnotationAction:(ARTAnnotationAction)value;
+ (instancetype)newWithAnnotationAction:(ARTAnnotationAction)value;

- (instancetype)initWithAnnotationType:(NSString *)type;
+ (instancetype)newWithAnnotationType:(NSString *)type;
@end

NS_ASSUME_NONNULL_END
