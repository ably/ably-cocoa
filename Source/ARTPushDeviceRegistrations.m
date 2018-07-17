//
//  ARTPushDeviceRegistrations.m
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushDeviceRegistrations.h"
#import "ARTHttp.h"
#import "ARTLog.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTClientOptions.h"
#import "ARTEncoder.h"
#import "ARTRest+Private.h"
#import "ARTLocalDevice.h"

@implementation ARTPushDeviceRegistrations {
    __weak ARTRest *_rest;
    __weak ARTLog* _logger;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _queue = rest.queue;
        _userQueue = rest.userQueue;
    }
    return self;
}

- (void)deviceAuthentication:(ARTDeviceId *)deviceId request:(NSMutableURLRequest *)request localDevice:(ARTLocalDevice *)localDevice {
    if ([localDevice.id isEqualToString:deviceId]) {
        if (localDevice.identityTokenDetails) {
            [_logger debug:__FILE__ line:__LINE__ message:@"adding device authentication using local device identity token"];
            [request setValue:[localDevice.identityTokenDetails.token base64Encoded] forHTTPHeaderField:@"X-Ably-DeviceIdentityToken"];
        }
        else if (localDevice.secret) {
            [_logger debug:__FILE__ line:__LINE__ message:@"adding device authentication using local device secret"];
            [request setValue:localDevice.secret forHTTPHeaderField:@"X-Ably-DeviceSecret"];
        }
    }
}

- (void)save:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

    ARTLocalDevice *local = _rest.device;

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:deviceDetails.id] resolvingAgainstBaseURL:NO];
    if (_rest.options.pushFullWait) {
        components.queryItems = @[[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [[_rest defaultEncoder] encodeDeviceDetails:deviceDetails error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [self deviceAuthentication:deviceDetails.id request:request localDevice:local];

    [_logger debug:__FILE__ line:__LINE__ message:@"save device with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            NSError *decodeError = nil;
            ARTDeviceDetails *deviceDetails = [[_rest defaultEncoder] decodeDeviceDetails:data error:&decodeError];
            if (decodeError) {
                [_logger debug:__FILE__ line:__LINE__ message:@"%@: decode device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
                callback([ARTErrorInfo createFromNSError:decodeError]);
            }
            else {
                [_logger debug:__FILE__ line:__LINE__ message:@"%@: successfully saved device %@", NSStringFromClass(self.class), deviceDetails.id];
                callback(nil);
            }
        }
        else if (error) {
            [_logger error:@"%@: save device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            [_logger error:@"%@: save device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *, ARTErrorInfo *))callback {
    if (callback) {
        void (^userCallback)(ARTDeviceDetails *, ARTErrorInfo *error) = callback;
        callback = ^(ARTDeviceDetails *device, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(device, error);
            });
        };
    }

    ARTLocalDevice *local = _rest.device;

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:deviceId]];
    request.HTTPMethod = @"GET";

    [self deviceAuthentication:deviceId request:request localDevice:local];

    [_logger debug:__FILE__ line:__LINE__ message:@"get device with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            NSError *decodeError = nil;
            ARTDeviceDetails *device = [_rest.encoders[response.MIMEType] decodeDeviceDetails:data error:&decodeError];
            if (decodeError) {
                [_logger debug:__FILE__ line:__LINE__ message:@"%@: decode device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
                callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
            }
            else if (device) {
                [_logger debug:__FILE__ line:__LINE__ message:@"%@: get device successfully", NSStringFromClass(self.class)];
                callback(device, nil);
            }
            else {
                [_logger debug:__FILE__ line:__LINE__ message:@"%@: get device failed with unknown error", NSStringFromClass(self.class)];
                callback(nil, [ARTErrorInfo createUnknownError]);
            }
        }
        else if (error) {
            [_logger error:@"%@: get device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback(nil, [ARTErrorInfo createFromNSError:error]);
        }
        else {
            [_logger error:@"%@: get device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback(nil, [ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)list:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTPaginatedResult<ARTDeviceDetails *> *result, ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [_rest.encoders[response.MIMEType] decodeDevicesDetails:data error:error];
    };
    [ARTPaginatedResult executePaginated:_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)remove:(NSString *)deviceId callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:deviceId] resolvingAgainstBaseURL:NO];
    if (_rest.options.pushFullWait) {
        components.queryItems = @[[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"remove device with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*Ok*/ || response.statusCode == 204 /*not returning any content*/) {
            [_logger debug:__FILE__ line:__LINE__ message:@"%@: save device successfully", NSStringFromClass(self.class)];
            callback(nil);
        }
        else if (error) {
            [_logger error:@"%@: remove device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            [_logger error:@"%@: remove device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    if (_rest.options.pushFullWait) {
        components.queryItems = [components.queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"remove devices with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*Ok*/ || response.statusCode == 204 /*not returning any content*/) {
            [_logger debug:__FILE__ line:__LINE__ message:@"%@: remove devices successfully", NSStringFromClass(self.class)];
            callback(nil);
        }
        else if (error) {
            [_logger error:@"%@: remove devices failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            [_logger error:@"%@: remove devices failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

@end
