#import <Foundation/Foundation.h>
#import "ARTRestChannels+Private.h"
#import "ARTChannels+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions+TestConfiguration.h"
#import "ARTTestClientOptions.h"

@implementation ARTRestChannels {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRestChannelsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (BOOL)exists:(NSString *)name {
    return [_internal exists:(NSString *)name];
}

- (ARTRestChannel *)get:(NSString *)name {
    return [[ARTRestChannel alloc] initWithInternal:[_internal get:(NSString *)name] queuedDealloc:_dealloc];
}

- (ARTRestChannel *)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [[ARTRestChannel alloc] initWithInternal:[_internal get:(NSString *)name options:(ARTChannelOptions *)options] queuedDealloc:_dealloc];
}

- (void)release:(NSString *)name {
    [_internal release:(NSString *)name];
}

- (id<NSFastEnumeration>)iterate {
    return [_internal copyIntoIteratorWithMapper:^ARTRestChannel *(ARTRestChannelInternal *internalChannel) {
        return [[ARTRestChannel alloc] initWithInternal:internalChannel queuedDealloc:self->_dealloc];
    }];
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface ARTRestChannelsInternal ()

@property (weak, nonatomic, nullable) ARTRestInternal *rest; // weak because rest owns self
@property (nonatomic, readonly) ARTInternalLog *logger;

@end

NS_ASSUME_NONNULL_END

@interface ARTRestChannelsInternal () <ARTChannelsDelegate>
@end

@implementation ARTRestChannelsInternal {
    ARTChannels *_channels;
}

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _rest = rest;
        _channels = [[ARTChannels alloc] initWithDelegate:self dispatchQueue:_rest.queue prefix:rest.options.testOptions.channelNamePrefix];
        _logger = logger;
    }
    return self;
}

- (id)makeChannel:(NSString *)name options:(ARTChannelOptions *)options {
    return [[ARTRestChannelInternal alloc] initWithName:name withOptions:options andRest:_rest logger:_logger];
}

- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(ARTRestChannel *(^)(ARTRestChannelInternal *))mapper {
    return [_channels copyIntoIteratorWithMapper:mapper];
}

- (ARTRestChannelInternal *)get:(NSString *)name {
    return [_channels get:name];
}

- (ARTRestChannelInternal *)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [_channels get:name options:options];
}

- (BOOL)exists:(NSString *)name {
    return [_channels exists:name];
}

- (void)release:(NSString *)name {
    [_channels release:name];
}

- (ARTRestChannelInternal *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options addPrefix:(BOOL)addPrefix {
    return [_channels _getChannel:name options:options addPrefix:addPrefix];
}

@end
