@import Foundation;

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTReachability <NSObject>

- (instancetype)initWithLogger:(ARTInternalLog *)logger queue:(dispatch_queue_t)queue;

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback;
- (void)off;

@end

NS_ASSUME_NONNULL_END
