#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTProtocolMessage;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@interface ARTQueuedMessage : NSObject

@property (readonly, nonatomic) ARTProtocolMessage *msg;
@property (readonly, nonatomic) NSMutableArray *sentCallbacks;
@property (readonly, nonatomic) NSMutableArray *ackCallbacks;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(nullable ARTCallback)sentCallback ackCallback:(nullable ARTStatusCallback)ackCallback;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg maxSize:(NSInteger)maxSize sentCallback:(nullable ARTCallback)sentCallback ackCallback:(nullable ARTStatusCallback)ackCallback;

- (ARTCallback)sentCallback;
- (ARTStatusCallback)ackCallback;

@end

NS_ASSUME_NONNULL_END
