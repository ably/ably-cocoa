//
//  ARTAppSetup.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTAppSetup.h"

@implementation ARTAppSetup

+ (void)setupApp:(ARTOptions *)options cb:(void (^)(ARTOptions *))cb {
    NSDictionary *capability = @{
        @"cansubscribe:*":@[@"subscribe"],
        @"canpublish:*":@[@"publish"],
        @"canpublish:andpresence":@[@"presence",@"publish"]
    };

    NSString *capabilityString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:capability options:0 error:nil] encoding:NSUTF8StringEncoding];

    NSDictionary *appSpec = @{
        @"keys": @[
            @{},
            @{@"capability":capabilityString}
        ],
        @"namespaces": @[
            @{@"id": @"persisted", @"persisted":[NSNumber numberWithBool:YES]}
        ],
        @"channels": @[
            @{
                @"name": @"persisted:presence_fixtures",
                @"presence": @[
                    @{@"clientId": @"client_bool", @"data": @"true"},
                    @{@"clientId": @"client_int", @"data":@"24"},
                    @{@"clientId": @"client_string", @"data":@"This is a string clientData payload"},
                    @{@"clientId": @"client_json", @"data":@"{\"test\":\"This is a JSONObject clientData payload\"}"}
                ]
            }
        ]
    };

    NSData *appSpecData = [NSJSONSerialization dataWithJSONObject:appSpec options:0 error:nil];
    NSLog(@"%@", [[NSString alloc] initWithData:appSpecData encoding:NSUTF8StringEncoding]);

    NSString *urlStr = [NSString stringWithFormat:@"https://%@:%d/apps", options.restHost, options.restPort];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    req.HTTPMethod = @"POST";
    req.HTTPBody = appSpecData;
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSLog(@"Creating test app. URL: %@, Method: %@, Body: %@, Headers: %@", req.URL, req.HTTPMethod, [[NSString alloc] initWithData:req.HTTPBody encoding:NSUTF8StringEncoding], req.allHTTPHeaderFields);

    CFRunLoopRef rl = CFRunLoopGetCurrent();

    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *keyId;
        NSString *keyValue;
        NSLog(@"http Response IS ---- %@", httpResponse);
        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSLog(@"Status Code: %ld", (long)httpResponse.statusCode);
            NSLog(@"Body: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            cb(nil);
            return;
        } else {
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
            if (response) {
                NSDictionary *key = response[@"keys"][0];
                keyId = [NSString stringWithFormat:@"%@.%@", response[@"appId"], key[@"id"]];

                keyValue = key[@"value"];
            }
        }

        ARTOptions *appOptions = [options clone];
        NSLog(@"options is cloned frmo %@", appOptions);
        appOptions.authOptions.keyId = keyId;
        appOptions.authOptions.keyValue = keyValue;

        CFRunLoopPerformBlock(rl, kCFRunLoopDefaultMode, ^{
            cb(appOptions);
        });
        CFRunLoopWakeUp(rl);
    }];
    [task resume];
}

+ (NSString *) realtimeHost
{
    return @"sandbox-realtime.ably.io";
}

+ (NSString *) restHost
{
    return @"sandbox-rest.ably.io";
}

+(ARTOptions *) binaryRestOptions
{
    ARTOptions * json = [[ARTOptions alloc] init];
    json.restHost = [ARTAppSetup restHost];
    json.binary =true;
    return json;
}

+(ARTOptions *) jsonRestOptions
{
    ARTOptions * json = [[ARTOptions alloc] init];
    json.restHost = [ARTAppSetup restHost];
    json.binary =false;
    return json;
}

+(float) timeout
{
    return 20.0;
    
}
@end
