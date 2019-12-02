//  Copyright © 2019 Ably. All rights reserved.

@import XCTest;
#import <Ably/ARTCrypto.h>
#import <Ably/ARTCrypto+Private.h>

@interface CryptoTest : XCTestCase
@end

@implementation CryptoTest

/**
 Test encryption and decryption using a 256 bit key and varying lengths of data.
 */
-(void)testEncryptAndDecrypt {
    // Configure the cipher.
    const UInt8 keyBytes[] = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32,
    };
    const UInt8 ivBytes[] = {
        16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
    };
    NSData *const key = [NSData dataWithBytes:keyBytes length:32];
    NSData *const iv = [NSData dataWithBytes:ivBytes length:16];
    ARTCipherParams *const params =
        [[ARTCipherParams alloc] initWithAlgorithm:@"aes" key:key iv:iv];
    id<ARTChannelCipher> cipher = [ARTCrypto cipherWithParams:params];
    
    // Prepare message data.
    const NSUInteger maxLength = 70;
    UInt8 messageData[maxLength];
    for (NSUInteger i = 1; i <= maxLength; i++) {
        messageData[i - 1] = i;
    }

    // Perform encrypt and decrypt on message data trimmed at all lengths up
    // to and including maxLength.
    for (NSUInteger i = 1; i <= maxLength; i++) {
        // Encrypt i bytes from the start of the message data.
        NSData *const dIn = [NSData dataWithBytes:&messageData length:i];
        NSData * dOut;
        XCTAssertEqual(ARTStateOk, [cipher encrypt:dIn output:&dOut].state);
        
        // Decrypt the encrypted data and verify the result is the same as what
        // we submitted for encryption.
        NSData * dVerify;
        XCTAssertEqual(ARTStateOk, [cipher decrypt:dOut output:&dVerify].state);
        XCTAssertEqualObjects(dIn, dVerify);
    }
}

@end
