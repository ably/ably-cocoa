//
//  AuthRevocationTests.m
//  Ably
//
//  Created by Ikbal Kaya on 15/06/2022.
//  Copyright © 2022 Ably. All rights reserved.
//

#import "AuthRevocationTests.h"

@implementation AuthRevocationTests

-(void)test_art_revocation {
   
   ARTRest* rest = [[ARTRest alloc] initWithKey:@"xxxx:xxxx"];
    ARTTokenRevocationTarget *firstTarget = [[ARTTokenRevocationTarget alloc] initWith:@"client1" value:@"client1@gmail.com"];
    NSArray<ARTTokenRevocationTarget *> *targets = @[firstTarget];
    [rest.auth revokeTokens:targets issuedBefore:nil allowReauthMargin:NO callback:^(ARTTokenRevocationResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error");
        }
        XCTAssert([error.userInfo isEqual:@"hello"]);
    }];
   
}


@end
