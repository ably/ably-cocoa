#import <Ably/ARTChannel.h>
#import <Ably/ARTDataEncoder.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRestInternal;
@class ARTInternalLog;

@interface ARTChannel()

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options rest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

@property (readonly, nullable) ARTChannelOptions *options;

@property (nonatomic, readonly) ARTDataEncoder *dataEncoder;

- (void)internalPostMessages:(id)data callback:(nullable ARTCallback)callback;
- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages;

- (nullable ARTChannelOptions *)options;
- (nullable ARTChannelOptions *)options_nosync;
- (void)setOptions:(ARTChannelOptions *_Nullable)options;
- (void)setOptions_nosync:(ARTChannelOptions *_Nullable)options;

@end

NS_ASSUME_NONNULL_END
