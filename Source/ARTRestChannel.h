#import <Foundation/Foundation.h>

#import <Ably/ARTChannel.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTRestPresence;
@class ARTPushChannel;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTRestChannelProtocol <ARTChannelProtocol>

@property (readonly, nullable) ARTChannelOptions *options;

- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)status:(ARTChannelDetailsCallback)callback;

- (void)setOptions:(ARTChannelOptions *_Nullable)options;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables messages to be published and historic messages to be retrieved for a channel.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTRestChannel object provides a straightforward API for publishing messages and retrieving message history from a channel.
 * END LEGACY DOCSTRING
 */
@interface ARTRestChannel : NSObject <ARTRestChannelProtocol>

@property (readonly) ARTRestPresence *presence;
@property (readonly) ARTPushChannel *push;

@end

NS_ASSUME_NONNULL_END
