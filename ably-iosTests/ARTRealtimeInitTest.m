//
//  ARTRealtimeInitTets.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"

@interface ARTRealtimeInitTest : XCTestCase
{
    ARTRealtime *_realtime;
    
}
@end

@implementation ARTRealtimeInitTest


- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _realtime = nil;
    [super tearDown];
}

- (void)withRealtimeSpec:(NSDictionary *)spec cb:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [self setupApp:[ARTTestUtil jsonRealtimeOptions] spec:spec cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}


-(NSDictionary *) standardSpec
{
    NSDictionary *capability = @{
                                 @"cansubscribe:*":@[@"subscribe"],
                                 @"canpublish:*":@[@"publish"],
                                 @"canpublish:andpresence":@[@"presence",@"publish"]
                                 };
    
    NSString *capabilityString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:capability options:0 error:nil] encoding:NSUTF8StringEncoding];
    return @{
              @"keys": @[
              @{},
              @{@"capability":capabilityString}
              ],
              @"namespaces": @[@{@"id": @"persisted", @"persisted":[NSNumber numberWithBool:YES]}],
              @"channels": @[@{
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
}

-(void) setupApp:(ARTOptions *)options spec:(NSDictionary *) appSpec cb:(void (^)(ARTOptions *))cb  {

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
        NSString *keyId= @"";
        NSString *keyValue= @"";
        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSLog(@"Status Code: %ld", (long)httpResponse.statusCode);
            NSLog(@"Body: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            cb(nil);
            return;
        } else {
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if (response) {
                NSArray * keys = [response valueForKey:@"keys"];
                if(keys && [keys count] >0)
                {
                    NSDictionary *key = response[@"keys"][0];
                    keyId = [NSString stringWithFormat:@"%@.%@", response[@"appId"], key[@"id"]];
                    keyValue = key[@"value"];
                    
                }
            }
        }
        
        ARTOptions *appOptions = [options clone];
        appOptions.authOptions.keyId = keyId;
        appOptions.authOptions.keyValue = keyValue;
        
        CFRunLoopPerformBlock(rl, kCFRunLoopDefaultMode, ^{
            cb(appOptions);
        });
        CFRunLoopWakeUp(rl);
    }];
    [task resume];
}

- (void)testInitKeyOpts {
    //TODO actually write thte test.
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach"];
    NSDictionary * standard = [self standardSpec];
    NSMutableDictionary * spec =[NSMutableDictionary dictionary];
    [spec setValue:[standard valueForKey:@"keys"] forKey:@"keys"];
    
    NSLog(@"spec is %@", spec);
    
    [self withRealtimeSpec:spec cb:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testInitKeyStrng constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            XCTAssertEqual(ARTRealtimeConnected, state);
            [expectation fulfill];
            
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



/*
 //TODO instantiating libarary with just key string not supported. should it be?
- (void)testInitKeyString {
    XCTFail(@"TODO write test");
}
 */


/*
 
 //TODO write setup api. better artrealtime and artrest constructors.
- (void)testInitHost {
    XCTFail(@"TODO write test");
}
 */


/*
 //TODO tests that demonstrate that artoptions actually gets used by the setup code.
- (void)testInitPort {
    XCTFail(@"TODO write test");
}

- (void)testInitDefaultSecure {
    XCTFail(@"TODO write test");
}

- (void)testInitInsecure {
    XCTFail(@"TODO write test");
}
*/

/*
- (void)testLogCalled {
    XCTFail(@"TODO write test");
}

- (void)testLogLevel {
    XCTFail(@"TODO write test");
}
*/
@end
