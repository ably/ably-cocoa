#import "ARTWrapperSDKProxyRealtimeAnnotations+Private.h"
#import "ARTRealtimeAnnotations+Private.h"
#import "ARTWrapperSDKProxyOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyRealtimeAnnotations ()

@property (nonatomic, readonly) ARTRealtimeAnnotations *underlyingRealtimeAnnotations;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyRealtimeAnnotations

- (instancetype)initWithRealtimeAnnotations:(ARTRealtimeAnnotations *)annotations proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingRealtimeAnnotations = annotations;
        _proxyOptions = proxyOptions;
    }

    return self;
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [self.underlyingRealtimeAnnotations getForMessage:message query:query callback:callback];
}


- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [self.underlyingRealtimeAnnotations getForMessageSerial:messageSerial query:query callback:callback];
}


- (void)publish:(ARTAnnotation *)annotation callback:(ARTAnnotationErrorCallback)callback { 
    [self.underlyingRealtimeAnnotations publish:annotation callback:callback];
}


- (ARTEventListener *)subscribe:(ARTAnnotationCallback)callback { 
    return [self.underlyingRealtimeAnnotations subscribe:callback];
}


- (ARTEventListener *)subscribe:(NSString *)type callback:(ARTAnnotationCallback)callback { 
    return [self.underlyingRealtimeAnnotations subscribe:type callback:callback];
}


- (void)unpublish:(ARTAnnotation *)annotation callback:(ARTAnnotationErrorCallback)callback { 
    [self.underlyingRealtimeAnnotations unpublish:annotation callback:callback];
}

- (void)unsubscribe {
    [self.underlyingRealtimeAnnotations unsubscribe];
}

- (void)unsubscribe:(ARTEventListener *)listener {
    [self.underlyingRealtimeAnnotations unsubscribe:listener];
}

- (void)unsubscribe:(NSString *)type listener:(ARTEventListener *)listener { 
    [self.underlyingRealtimeAnnotations unsubscribe];
}

@end
