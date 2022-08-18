#import <Foundation/Foundation.h>

#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTChannelOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains an individual message that is sent to, or received from, Ably.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTMessage represents an individual message that is sent to or received from Ably.
 * END LEGACY DOCSTRING
 */
@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (nullable, readwrite, strong, nonatomic) NSString *name;

- (instancetype)initWithName:(nullable NSString *)name data:(id)data;
- (instancetype)initWithName:(nullable NSString *)name data:(id)data clientId:(NSString *)clientId;

@end

@interface ARTMessage (Decoding)

+ (nullable instancetype)fromEncoded:(NSDictionary *)jsonObject
                      channelOptions:(ARTChannelOptions *)options
                               error:(NSError *_Nullable *_Nullable)error;

+ (nullable NSArray<ARTMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray
                                      channelOptions:(ARTChannelOptions *)options
                                               error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
