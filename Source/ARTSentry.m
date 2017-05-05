//
//  ARTSentry.m
//  Ably
//
//  Created by Toni Cárdenas on 04/05/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTSentry.h"
#import "ARTURLSessionServerTrust.h"
#import "ARTNSDate+ARTUtil.h"
#import "ARTDefault.h"
#import "ARTCrypto+Private.h"
#import <KSCrash/KSCrash.h>
#import "ARTNSArray+ARTFunctional.h"

@implementation ARTSentry

NSString* ART_uuid() {
    NSMutableData *data = [ARTCrypto generateSecureRandomData:16];
    if (!data) {
        return nil;
    }
    uint8_t *bs = (uint8_t*)[data mutableBytes];
    bs[6] &= 0x0F; // clear version
    bs[6] |= 0x40; // set version to 4 (random uuid)
    bs[8] &= 0x3F; // clear variant
    bs[8] |= 0x80; // set to IETF variant
    NSMutableString *hex = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        [hex appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)bs[i]]];
    }
    return [NSString stringWithString:hex];
}

+ (void)report:(NSString *)message to:(NSString *)dns extra:(NSDictionary *_Nullable)extra breadcrumbs:(NSArray<NSDictionary *> *_Nullable)breadcrumbs tags:(NSDictionary *)tags exception:(NSException *_Nullable)exception {
    NSURL *dnsUrl = [NSURL URLWithString:dns];
    if (!dnsUrl) {
        NSLog(@"ARTSentry: logExceptionReportingUrl (%@) is not a valid URL; crash won't be reported", dns);
        return;
    }
    if (!dnsUrl.user || !dnsUrl.password) {
        NSLog(@"ARTSentry: logExceptionReportingUrl (%@) doesn't have public and secret key; crash won't be reported", dns);
        return;
    }
    NSString *authHeader = [NSString stringWithFormat:@"Sentry sentry_version=4, sentry_key=%@, sentry_secret=%@", dnsUrl.user, dnsUrl.password];
    NSString *projectID = [dnsUrl lastPathComponent];
    NSString *eventID = ART_uuid();
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    body[@"message"] = message;
    body[@"event_id"] = ART_orNull(eventID);
    body[@"project"] = ART_orNull(projectID);
    body[@"timestamp"] = ART_orNull([[NSDate date] toSentryTimestamp]);
    body[@"level"] = @"error";
    body[@"platform"] = @"cocoa";
    body[@"release"] = [ARTDefault libraryVersion];
    
    body[@"extra"] = extra;
    body[@"breadcrumbs"] = breadcrumbs;
    body[@"tags"] = tags;
    if (exception) {
        body[@"exception"] = @{
           @"value": ART_orNull(exception.reason),
           @"type": ART_orNull(exception.name),
       };
        
        
        NSArray<NSString *> *trace = [exception callStackSymbols];
        NSString *pattern = @"[ \t]*[0-9]+[ \t]*([^ \t]+)[ \t]+([^ \t]+)[ \t]+(.+) \\+ ([0-9]+)";
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSMutableArray<NSDictionary *> *frames = [[NSMutableArray alloc] initWithCapacity:trace.count];
        NSString *culprit = nil;
        for (int i = (int)trace.count - 1; i >= 0; i--) {
            NSString *line = trace[i];
            NSTextCheckingResult *match = [regex firstMatchInString:line options:NSMatchingAnchored range:NSMakeRange(0, [line length])];
            if (!match || match.range.length == 0) {
                continue;
            }
            NSString *function = [NSString stringWithFormat:@"%@::%@", [line substringWithRange:[match rangeAtIndex:1]], [line substringWithRange:[match rangeAtIndex:3]]];
            [frames addObject:@{
                @"function": function,
                @"instruction_addr": [line substringWithRange:[match rangeAtIndex:4]],
                @"symbol_addr": [line substringWithRange:[match rangeAtIndex:2]]
            }];
            if ([[line substringWithRange:[match rangeAtIndex:1]] isEqualToString:@"Ably"]) {
                culprit = function;
            }
        }
        body[@"stacktrace"] = @{
                                @"frames": frames
                                };
        if (culprit) {
            body[@"culprit"] = culprit;
        }
    }

    body[@"contexts"] = ART_deviceContexts();
    
    NSData *bodyData = nil;
    id jsonError = nil;
    @try {
        NSError *error = nil;
        bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
        jsonError = error;
    } @catch (NSException *exception) {
        jsonError = exception;
    }
    if (!bodyData) {
        NSLog(@"ARTSentry: error encoding crash report as JSON: %@", jsonError);
        return;
    }
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = dnsUrl.scheme;
    urlComponents.host = dnsUrl.host;
    urlComponents.port = dnsUrl.port;
    urlComponents.path = [NSString stringWithFormat:@"/api/%@/store/", projectID];
    NSURL *url = [urlComponents URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:authHeader forHTTPHeaderField:@"X-Sentry-Auth"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    
    ARTURLSessionServerTrust *session = [[ARTURLSessionServerTrust alloc] init];
    [session get:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error || !response) {
            NSLog(@"ARTSentry: error sending crash report: %@", error);
        } else if (response.statusCode >= 400) {
            NSLog(@"ARTSentry: error response from crash report: %ld, body: %@", (long)response.statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"ARTSentry: crash report sent successfully with ID %@", eventID);
        }
    }];
}

id ART_orNull(id obj) {
    return obj != nil ? obj : [NSNull null];
}

NSDictionary *ART_deviceContexts() {
    NSDictionary *info = [[KSCrash sharedInstance] systemInfo];

    NSString *model =
        #if TARGET_IPHONE_SIMULATOR
            [[[NSProcessInfo alloc] init] environment][@"SIMULATOR_MODEL_IDENTIFIER"]
        #elif TARGET_OS_MAC
            info[@"model"]
        #else
            info[@"machine"]
        #endif
    ;

    NSString *family = nil;
    if (model) {
        NSString *pattern = @"^\\D+";
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        family = [model substringWithRange:[regex firstMatchInString:model options:0 range:NSMakeRange(0, model.length)].range];
    }

    return @{
        @"os": @{
            @"name": ART_orNull(
                #if TARGET_OS_IOS
                    @"iOS"
                #elif TARGET_OS_TV
                    @"tvOS"
                #elif TARGET_OS_MAC
                    @"macOS"
                #elif TARGET_OS_WATCH
                    @"watchOS"
                #else
                    [NSNull null]
                #endif
            ),
            @"version": ART_orNull(info[@"systemVersion"]),
            @"build": ART_orNull(info[@"osVersion"]),
            @"kernel_version": ART_orNull(info[@"kernelVersion"]),
            @"rooted": ART_orNull(info[@"isJailbroken"]),
        },
        @"device": @{
            @"arch": ART_orNull(info[@"cpuArchitecture"]),
            @"model": ART_orNull(model),
            @"family": ART_orNull(family),
            @"free_memory": ART_orNull(info[@"freeMemory"]),
            @"memory_size": ART_orNull(info[@"memorySize"]),
            @"usable_memory": ART_orNull(info[@"usableMemory"]),
            @"storage_size": ART_orNull(info[@"storageSize"]),
            @"boot_time": ART_orNull(info[@"bootTime"]),
            @"timezone": ART_orNull(info[@"timezone"]),
        },
        @"app": @{
            @"app_start_time": ART_orNull(info[@"appStartTime"]),
            @"device_app_hash": ART_orNull(info[@"deviceAppHash"]),
            @"app_id": ART_orNull(info[@"appID"]),
            @"build_type": ART_orNull(info[@"buildType"]),
            @"app_identifier": ART_orNull(info[@"bundleID"]),
            @"app_name": ART_orNull(info[@"bundleName"]),
            @"app_build": ART_orNull(info[@"bundleVersion"]),
            @"app_version": ART_orNull(info[@"bundleShortVersion"]),
        },
    };
}

@end

