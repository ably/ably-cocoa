#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTChannelOptions.h>

/**
 ARTPresenceAction represents all actions an ``ARTPresenceMessage`` can indicate.
 */
typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    ARTPresenceAbsent = 0,
    ARTPresencePresent,
    ARTPresenceEnter,
    ARTPresenceLeave,
    ARTPresenceUpdate
};

NSString *_Nonnull ARTPresenceActionToStr(ARTPresenceAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 ARTPresenceMessage represents an individual presence update that is sent to or received from Ably.
 */
@interface ARTPresenceMessage : ARTBaseMessage

@property (readwrite, assign, nonatomic) ARTPresenceAction action;

- (nonnull NSString *)memberKey;

- (BOOL)isEqualToPresenceMessage:(nonnull ARTPresenceMessage *)presence;

- (BOOL)isNewerThan:(ARTPresenceMessage *)latest __attribute__((warn_unused_result));

@end

@interface ARTPresenceMessage (Decoding)

+ (nullable instancetype)fromEncoded:(NSDictionary *)jsonObject
                      channelOptions:(ARTChannelOptions *)options
                               error:(NSError *_Nullable *_Nullable)error;

+ (nullable NSArray<ARTPresenceMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray
                                              channelOptions:(ARTChannelOptions *)options
                                                       error:(NSError *_Nullable *_Nullable)error;

@end

#pragma mark - ARTEvent

@interface ARTEvent (PresenceAction)
- (instancetype)initWithPresenceAction:(ARTPresenceAction)value;
+ (instancetype)newWithPresenceAction:(ARTPresenceAction)value;
@end

NS_ASSUME_NONNULL_END
