//
//  ARTAllTest.m
//  ably-ios
//
//  Created by vic on 23/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTStats.h"
#import "NSDate+ARTUtil.h"


@interface ARTAllTest : XCTestCase
{
     ARTRealtime *_realtime;
    ARTRest * _rest;
}
@end


//TODO RM?
@implementation ARTAllTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _realtime = nil;
    _rest = nil;
    
    [super tearDown];
}
- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}

- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}


/*ARTRESTCHANNELPUBLISHTEST**/






/****ARTREALTIMECHANNELTEST*/




@end
