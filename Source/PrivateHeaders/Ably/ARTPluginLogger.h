#import <Foundation/Foundation.h>
#import "APLogger.h"

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPluginLogger : NSObject<APLogger>

- (instancetype)initWithUnderlying:(ARTInternalLog *)underlying;

@end

NS_ASSUME_NONNULL_END
