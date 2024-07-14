/// ARTProtocolMessageFlag bitmask
typedef NS_OPTIONS(NSUInteger, ARTProtocolMessageFlag) {
    ARTProtocolMessageFlagHasPresence = (1UL << 0),
    ARTProtocolMessageFlagHasBacklog = (1UL << 1),
    ARTProtocolMessageFlagResumed = (1UL << 2),
    ARTProtocolMessageFlagHasLocalPresence = (1UL << 3),
    ARTProtocolMessageFlagTransient = (1UL << 4),
    ARTProtocolMessageFlagAttachResume = (1UL << 5),
    ARTProtocolMessageFlagPresence = (1UL << 16),
    ARTProtocolMessageFlagPublish = (1UL << 17),
    ARTProtocolMessageFlagSubscribe = (1UL << 18),
    ARTProtocolMessageFlagPresenceSubscribe = (1UL << 19)
};

NS_ASSUME_NONNULL_BEGIN

@interface ARTProtocolMessage ()

@property (readonly, nonatomic) BOOL ackRequired;

@property (readonly, nonatomic) BOOL hasPresence;
@property (readonly, nonatomic) BOOL hasBacklog;
@property (readonly, nonatomic) BOOL resumed;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg maxSize:(NSInteger)maxSize;

@end

NS_ASSUME_NONNULL_END
