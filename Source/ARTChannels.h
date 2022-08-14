#import <Foundation/Foundation.h>

@class ARTRest;
@class ARTRestChannel;
@class ARTChannelOptions;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates and destroys [`RestChannel`]{@link RestChannel} and [`RealtimeChannel`]{@link RealtimeChannel} objects.
 * END CANONICAL DOCSTRING
 */
@interface ARTChannels<ChannelType> : NSObject

- (BOOL)exists:(NSString *)name;
- (ChannelType)get:(NSString *)name;
- (ChannelType)get:(NSString *)name options:(ARTChannelOptions *)options;
- (void)release:(NSString *)name;
- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(id (^)(ChannelType))mapper;

@end
