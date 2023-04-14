#import "ARTLocalDeviceFetcher.h"
#import "ARTLocalDeviceFetcher+Testing.h"
#import "ARTLocalDevice+Private.h"

@interface ARTDefaultLocalDeviceFetcher ()

@property (nonatomic, nullable) ARTLocalDevice *device;
@property (nonatomic, readonly) dispatch_semaphore_t semaphore;

@end

@implementation ARTDefaultLocalDeviceFetcher

- (instancetype)init {
    if (self = [super init]) {
        _semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

// The device is shared in a static variable because it's a reflection
// of what's persisted. Having a device instance per ARTRest instance
// could leave some instances in a stale state, if, through another
// instance, the persisted state is changed.
//
// As a side effect, the first ARTRest instance "wins" at setting the device's
// client ID.
+ (ARTDefaultLocalDeviceFetcher *)sharedInstance {
    static ARTDefaultLocalDeviceFetcher *sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[ARTDefaultLocalDeviceFetcher alloc] init];
    });

    return sharedInstance;
}

- (ARTLocalDevice *)fetchLocalDeviceWithClientID:(NSString *)clientID storage:(id<ARTDeviceStorage>)storage logger:(ARTInternalLog *)logger {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (!self.device) {
        self.device = [ARTLocalDevice load:clientID storage:storage logger:logger];
    }
    ARTLocalDevice *const device = self.device;
    dispatch_semaphore_signal(self.semaphore);

    return device;
}

- (void)resetDevice {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    self.device = nil;
    dispatch_semaphore_signal(self.semaphore);
}

@end
