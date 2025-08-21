#ifdef ABLY_SUPPORTS_PLUGINS

#import <Foundation/Foundation.h>
@import _AblyPluginSupportPrivate;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPluginDecodingContext: NSObject <APDecodingContextProtocol>

- (instancetype)initWithParentID:(nullable NSString *)parentID
              parentConnectionID:(nullable NSString *)parentConnectionID
                 parentTimestamp:(nullable NSDate *)parentTimestamp
                   indexInParent:(NSInteger)indexInParent NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif
