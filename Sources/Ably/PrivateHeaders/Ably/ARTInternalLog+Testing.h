@import Foundation;

@protocol ARTInternalLogCore;

NS_ASSUME_NONNULL_BEGIN

@interface ARTInternalLog ()

@property (nonatomic, readonly) id<ARTInternalLogCore> core;

@end

NS_ASSUME_NONNULL_END
