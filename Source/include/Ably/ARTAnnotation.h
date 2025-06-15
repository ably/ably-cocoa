#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>

/**
 * Enumerates the possible values of the `action` field of an `ARTAnnotation`
 */
NS_SWIFT_SENDABLE
typedef NS_ENUM(NSUInteger, ARTAnnotationAction) {
    /**
     * A created annotation.
     */
    ARTAnnotationCreate,
    /**
     * A deleted annotation.
     */
    ARTAnnotationDelete,
};

/// :nodoc:
NSString *_Nonnull ARTAnnotationActionToStr(ARTAnnotationAction action);

NS_ASSUME_NONNULL_BEGIN

@interface ARTAnnotation : ARTBaseMessage

/// The action, whether this is an annotation being added or removed, one of the `ARTAnnotationAction` enum values.
@property (readwrite, nonatomic) ARTAnnotationAction action;

/// This annotation's unique serial (lexicographically totally ordered).
@property (nullable, readwrite, nonatomic) NSString *serial;

/// The serial of the message (of type `MESSAGE_CREATE`) that this annotation is annotating.
@property (nullable, readwrite, nonatomic) NSString *messageSerial;

/// The type of annotation it is, typically some identifier together with an aggregation method; for example: "emoji:distinct.v1". Handled opaquely by the SDK and validated serverside.
@property (nullable, readwrite, nonatomic) NSString *type;

/// The name of this annotation. This is the field that most annotation aggregations will operate on. For example, using "distinct.v1" aggregation (specified in the type), the message summary will show a list of clients who have published an annotation with each distinct annotation.name.
@property (nullable, readwrite, nonatomic) NSString *name;

/// An optional count, only relevant to certain aggregation methods, see aggregation methods documentation for more info.
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
