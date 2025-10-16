#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
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

NS_SWIFT_SENDABLE
@interface ARTAnnotation : NSObject<NSCopying>

/// A Unique ID assigned by Ably to this message.
@property (nullable, readonly, nonatomic) NSString *id;

/// The action, whether this is an annotation being added or removed, one of the `ARTAnnotationAction` enum values.
@property (readonly, nonatomic) ARTAnnotationAction action;

/// The client ID of the publisher of this message.
@property (nonatomic, readonly, nullable) NSString *clientId;

/// The name of this annotation. This is the field that most annotation aggregations will operate on. For example, using "distinct.v1" aggregation (specified in the type), the message summary will show a list of clients who have published an annotation with each distinct annotation.name.
@property (nullable, readonly, nonatomic) NSString *name;

/// An optional count, only relevant to certain aggregation methods, see aggregation methods documentation for more info.
@property (nullable, readonly, nonatomic) NSNumber *count;

/// The message payload, if provided.
@property (nonatomic, readonly, nullable) id data;

/// This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
@property (nonatomic, readonly, nullable) NSString *encoding;

/// Timestamp of when the message was received by Ably, as a `NSDate` object.
@property (nullable, nonatomic, readonly) NSDate *timestamp;

/// This annotation's unique serial (lexicographically totally ordered).
@property (readonly, nonatomic) NSString *serial;

/// The serial of the message (of type `MESSAGE_CREATE`) that this annotation is annotating.
@property (readonly, nonatomic) NSString *messageSerial;

/// The type of annotation it is, typically some identifier together with an aggregation method; for example: "emoji:distinct.v1". Handled opaquely by the SDK and validated serverside.
@property (readonly, nonatomic) NSString *type;

/// A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
@property (nullable, readonly, nonatomic) id<ARTJsonCompatible> extras;

- (instancetype)initWithId:(nullable NSString *)annotationId
                    action:(ARTAnnotationAction)action
                  clientId:(nullable NSString *)clientId
                      name:(nullable NSString *)name
                     count:(nullable NSNumber *)count
                      data:(nullable id)data
                  encoding:(nullable NSString *)encoding
                 timestamp:(nullable NSDate *)timestamp
                    serial:(nullable NSString *)serial
             messageSerial:(NSString *)messageSerial
                      type:(NSString *)type
                    extras:(nullable id<ARTJsonCompatible>)extras;

@end

#pragma mark - ARTEvent

/// :nodoc:
@interface ARTEvent (AnnotationType)
- (instancetype)initWithAnnotationType:(NSString *)type;
+ (instancetype)newWithAnnotationType:(NSString *)type;
@end

NS_ASSUME_NONNULL_END
