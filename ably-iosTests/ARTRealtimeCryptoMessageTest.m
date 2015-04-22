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
#import "ARTLog.h"
@interface ARTRealtimeCryptoMessageTest : XCTestCase

@end

@implementation ARTRealtimeCryptoMessageTest

- (void)setUp {
    [super setUp];
    [ARTLog setLogLevel:ArtLogLevelDebug];
    [ARTLog setLogCallback:nil];
    
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

-(void) testCBCParser256 {
    NSArray * encoders = [ARTPayload parseEncodingChain:@"utf-8/cipher+aes-256-cbc/base64"
                                                    key:[[NSData alloc] initWithBase64EncodedString:@"o9qXZoPGDNla50VnRwH7cGqIrpyagTxGsRgimKJbY40=" options:0]
                                                     iv:[[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
    XCTAssertEqual([encoders count], 3);
    id<ARTPayloadEncoder> utf8 = [encoders objectAtIndex:0];
    id<ARTPayloadEncoder> cipher128 = [encoders objectAtIndex:1];
    id<ARTPayloadEncoder> base64 = [encoders objectAtIndex:2];
    XCTAssertEqualObjects([utf8 name], @"utf-8");
    XCTAssertEqualObjects([cipher128 name], @"cipher+aes-256-cbc");
    XCTAssertEqualObjects([base64 name], @"base64");
    
    
}


-(void) testCaseByFileContents:(NSString *) str {

    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * topLevel =[NSJSONSerialization JSONObjectWithData:data  options:NSJSONReadingMutableContainers error:nil];
    NSString * key = [topLevel valueForKey:@"key"];
    NSString * iv = [topLevel valueForKey:@"iv"];
    NSArray * items = [topLevel valueForKey:@"items"];
    for(int i=0;i < [items count]; i++) {
        
  
        NSDictionary * item = [items objectAtIndex:i];
        NSString * dataStr = [[item valueForKey:@"encoded"] valueForKey:@"data"];
        NSString * simpleEncoding = [[item valueForKey:@"encoded"] valueForKey:@"encoding"];
        if(!simpleEncoding) {
            simpleEncoding = @"";
        }
        NSString * encData = [[item valueForKey:@"encrypted"] valueForKey:@"data"];
        NSString * encoding = [[item valueForKey:@"encrypted"] valueForKey:@"encoding"];

        NSArray * encoders = [ARTPayload parseEncodingChain:encoding
                                                        key:[[NSData alloc] initWithBase64EncodedString:key options:0]
                                                         iv:[[NSData alloc] initWithBase64EncodedString:iv options:0]];

        NSData * encodableData = [simpleEncoding isEqualToString:@"base64"] ?
        [[NSData alloc] initWithBase64EncodedString:dataStr options:0] : [dataStr dataUsingEncoding:NSUTF8StringEncoding];

        id<ARTPayloadEncoder> encoderChain =[[ARTPayloadEncoderChain alloc] initWithEncoders:encoders];
        
        //check encoded result matches the encoded string in the file
        {
       
            ARTPayload * p = [[ARTPayload alloc] initWithPayload:encodableData encoding:encoding];
            ARTPayload * outputPayload = nil;
            [encoderChain encode:p output:&outputPayload];
            XCTAssertEqualObjects(outputPayload.payload, encData);
        }
        
        //check decoded result matches the decoded string in the file
        {
            ARTPayload * decP = [[ARTPayload alloc] initWithPayload:encData encoding:encoding];
            ARTPayload * decOutput = nil;
            [encoderChain decode:decP output:&decOutput];

            NSString * decodedStr = decOutput.payload;
            if([simpleEncoding isEqualToString:@"base64"]) {
                XCTAssertEqualObjects(decOutput.payload, encodableData);
            }
            else if([simpleEncoding isEqualToString:@"json"]) {
                //we don't want to compare json as strings, but as arrays or dictionarys
                ARTPayload * p =[[ARTPayload alloc] initWithPayload:encodableData encoding:@"json"];
                ARTJsonPayloadEncoder * e = [ARTJsonPayloadEncoder instance];
                ARTPayload* jsonOut = nil;
                [e encode:p output:&jsonOut];
                ARTPayload * decodedEncoded = nil;
                [e decode:jsonOut output:&decodedEncoded];
                if([decOutput.payload isKindOfClass:[NSDictionary class]]) {
                    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:decodedEncoded.payload options:0 error:nil];
                    XCTAssertEqualObjects(dictionary, decOutput.payload);
                }
                else if([decOutput.payload isKindOfClass:[NSArray class]]) {
                    NSArray * array = [NSJSONSerialization JSONObjectWithData:decodedEncoded.payload options:0 error:nil];
                    XCTAssertEqualObjects(array, decOutput.payload);
                }
            }
            else {
                XCTAssertEqualObjects(decodedStr, dataStr);
            }
        }
    }
}



- (void)testEncrypt_128 {
    [self testCaseByFileContents:[ARTTestUtil getCrypto128Json]];
}

- (void)testEncrypt_256 {
    [self testCaseByFileContents:[ARTTestUtil getCrypto256Json]];
}


@end
