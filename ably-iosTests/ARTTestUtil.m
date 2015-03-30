//
//  ARTTestUtil.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTTestUtil.h"

@implementation ARTTestUtil


+(void) setupApp:(ARTOptions *)options withAlteration:(TestAlteration) alt  appId:(NSString *) appId cb:(void (^)(ARTOptions *))cb
{
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
    NSLog(@" setupApp: %@", [[NSString alloc] initWithData:appSpecData encoding:NSUTF8StringEncoding]);
    
    
    if(alt ==TestAlterationBadWsHost)
    {
        [options setRealtimeHost:[options.realtimeHost stringByAppendingString:@"/badRealtimeEndpoint"] withRestHost:[options.restHost stringByAppendingString:@"/badRestEndpoint"]];
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"https://%@:%d/apps", options.restHost, options.restPort];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    req.HTTPMethod = @"POST";
    req.HTTPBody = appSpecData;
    if(false  ||options.binary) { //msgpack not implemented yet
        [req setValue:@"application/x-msgpack,application/json" forHTTPHeaderField:@"Accept"];
        [req setValue:@"application/x-msgpack" forHTTPHeaderField:@"Content-Type"];
        
    }
    else {
        [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        
    }
    
    NSLog(@"Creating test app. URL: %@, Method: %@, Body: %@, Headers: %@", req.URL, req.HTTPMethod, [[NSString alloc] initWithData:req.HTTPBody encoding:NSUTF8StringEncoding], req.allHTTPHeaderFields);
    
    CFRunLoopRef rl = CFRunLoopGetCurrent();
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    
    
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *keyId;
        NSString *keyValue;
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
        
        appOptions.authOptions.keyId = keyId;
        appOptions.authOptions.keyValue = keyValue;
        if(alt == TestAlterationBadKeyId)
        {
            appOptions.authOptions.keyId= @"badKeyId";
        }
        else if(alt == TestAlterationBadKeyValue)
        {
            appOptions.authOptions.keyValue = @"badKeyValue";
        }
        
        CFRunLoopPerformBlock(rl, kCFRunLoopDefaultMode, ^{
            cb(appOptions);
        });
        CFRunLoopWakeUp(rl);
    }];
    [task resume];

}

+(NSString *) appIdFromkeyId:(NSString *) keyId
{
    NSArray *array = [keyId componentsSeparatedByString:@"."];
    return [array objectAtIndex:0];
}

+(void) setupApp:(ARTOptions *)options withAlteration:(TestAlteration) alt cb:(void (^)(ARTOptions *))cb {
    [ARTTestUtil setupApp:options withAlteration:alt appId:nil cb:cb];
}

+ (void)setupApp:(ARTOptions *)options cb:(void (^)(ARTOptions *))cb {
    [ARTTestUtil setupApp:options withAlteration:TestAlterationNone cb:cb];
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
    json.restHost = [ARTTestUtil restHost];
    json.binary =true;
    return json;
}

+(ARTOptions *) jsonRestOptions
{
    ARTOptions * json = [[ARTOptions alloc] init];
    json.restHost = [ARTTestUtil restHost];
    json.binary =false;
    return json;
}

+(ARTOptions *) jsonRealtimeOptions
{
    ARTOptions * json = [[ARTOptions alloc] init];
    
    [json setRealtimeHost:[ARTTestUtil realtimeHost] withRestHost:[ARTTestUtil restHost]];

    json.binary =false;
    return json;
}

+(ARTOptions *) binaryRealtimeOptions
{
    ARTOptions * json = [[ARTOptions alloc] init];
    [json setRealtimeHost:[ARTTestUtil realtimeHost] withRestHost:[ARTTestUtil restHost]];

    json.binary =true;
    return json;
}




+ (void)repeat:(int)count delay:(NSTimeInterval)delay block:(void (^)(int))block {
    [ARTTestUtil repeat:count i:0 delay:delay block:block];
}

+ (void)repeat:(int)count i:(int)i delay:(NSTimeInterval)delay block:(void (^)(int))block {
    if (count == 0) {
        return;
    }
    NSLog(@"count: %d, i: %d", count, i);
    block(i);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ARTTestUtil repeat:(count - 1) i:(i + 1) delay:delay block:block];
    });
}

+(long long) nowMilli
{
    NSDate * date = [NSDate date];
    return [date timeIntervalSince1970]*1000;
}

+(float) smallSleep
{
    return 1.75;
}
+(float) bigSleep
{
    return 3.0;
    
}
+(float) timeout
{
    return 120.0;
    
}

@end
