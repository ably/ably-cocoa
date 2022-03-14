#import <Foundation/Foundation.h>

#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTChannelOptions.h>

NS_ASSUME_NONNULL_BEGIN

/// ARTMessage represents an individual message that is sent to or received from Ably.
@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (nullable, readwrite, strong, nonatomic) NSString *name;

- (instancetype)initWithName:(nullable NSString *)name data:(id)data;
- (instancetype)initWithName:(nullable NSString *)name data:(id)data clientId:(NSString *)clientId;

@end

@interface ARTMessage (Decryption)

+ (instancetype)fromEncodedJsonObject:(NSDictionary *)json channelOptions:(ARTChannelOptions *)options error:(NSError **)error;
+ (NSArray<ARTMessage *> *)fromEncodedJsonArray:(NSArray<NSDictionary *> *)jsonArray channelOptions:(ARTChannelOptions *)options error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
