//
//  ARTRealtimeCryptoMessageTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTTestUtil.h"
#import "ARTPayload.h"
#import "ARTPayload+Private.h"
@interface ARTRealtimeCryptoMessageTest : XCTestCase

@end

@implementation ARTRealtimeCryptoMessageTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


-(void) testCBCParser {

    
    NSArray * encoders = [ARTPayload parseEncodingChain:@"utf-8/cipher+aes-128-cbc/base64"
                                                    key:[[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0]
                                                     iv:[[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
    XCTAssertEqual([encoders count], 3);
    id<ARTPayloadEncoder> utf8 = [encoders objectAtIndex:0];
    id<ARTPayloadEncoder> cipher128 = [encoders objectAtIndex:1];
    id<ARTPayloadEncoder> base64 = [encoders objectAtIndex:2];
    XCTAssertEqualObjects([utf8 name], @"utf-8");
    XCTAssertEqualObjects([cipher128 name], @"cipher+aes-128-cbc");
    XCTAssertEqualObjects([base64 name], @"base64");
    
    
}



- (void)testEncrypt_128 {
    NSString * str = [ARTTestUtil getCrypto128Json];
    NSLog(@"128 json is %@", str);
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * topLevel =[NSJSONSerialization JSONObjectWithData:data  options:NSJSONReadingMutableContainers error:nil];
    
    NSString * algorithm = [topLevel valueForKey:@"algorithm"];
    NSString * mode = [topLevel valueForKey:@"mode"];
    int keyLength = [[topLevel valueForKey:@"keylength"] intValue];
    NSString * key = [topLevel valueForKey:@"key"];
    NSString * iv = [topLevel valueForKey:@"iv"];
    NSArray * items = [topLevel valueForKey:@"items"];
    for(int i=0;i < [items count]; i++) {
        NSDictionary * item = [items objectAtIndex:i];
        NSString * name = [[item valueForKey:@"encoded"] valueForKey:@"name"];
        NSString * data = [[item valueForKey:@"encoded"] valueForKey:@"data"];
        NSString * simpleEncoding = [[item valueForKey:@"encoded"] valueForKey:@"encoding"];
        if(!simpleEncoding) {
            simpleEncoding = @"";
        }
        NSString * encName = [[item valueForKey:@"encrypted"] valueForKey:@"name"];
        NSString * encData = [[item valueForKey:@"encrypted"] valueForKey:@"data"];
        NSString * encoding = [[item valueForKey:@"encrypted"] valueForKey:@"encoding"];
        
        NSLog(@" %@, %@, %@, %@, %@, %@", name, data, simpleEncoding, encName, encData, encoding);
        
        NSData * dataObj = [str dataUsingEncoding:NSUTF8StringEncoding];
        ARTPayload *payload = [ARTPayload payloadWithPayload:dataObj encoding:encoding];
        ARTPayload *decoded = nil;
        ARTStatus status = [[ARTBase64PayloadEncoder instance] decode:payload output:&decoded];
        XCTAssertEqual(status, ARTStatusOk);
        
        id decodedData =decoded.payload;
        NSLog(@"DECODED DATA IS %@", decodedData);
    }
    
    NSLog(@"algo %@", algorithm);
   //  ARTPayload *payload = [ARTPayload payloadWithPayload:data encoding:encoding];
   // ARTPayload *decoded = nil;
   // ARTStatus status = [[ARTBase64PayloadEncoder instance] decode:payload output:&decoded];
   // XCTAssertEqual(status, ARTStatusOk);
    
}

- (void)testEncrypt_256 {
    XCTFail(@"TODO write test");
}

- (void)testDecrypt_128 {
    XCTFail(@"TODO write test");
}

- (void)testDecrypt_256 {
    XCTFail(@"TODO write test");
}

@end
