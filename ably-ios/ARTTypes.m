//
//  ARTTypes.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTTypes.h"

// MARK: Global helper functions

__GENERIC(NSArray, NSString *) *decomposeKey(NSString *key) {
    return [key componentsSeparatedByString:@":"];
}

NSString *decodeBase64(NSString *base64) {
    NSData *dataB64 = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
    return [[NSString alloc] initWithData:dataB64 encoding:NSUTF8StringEncoding];
}

// MARK: ARTIndirectCancellable

@interface ARTIndirectCancellable ()

@property (readwrite, assign, nonatomic) BOOL isCancelled;

@end

@implementation ARTIndirectCancellable

- (instancetype)init {
    self = [super init];
    if (self) {
        _cancellable = nil;
        _isCancelled = NO;
    }
    return self;
}

- (instancetype)initWithCancellable:(id<ARTCancellable>)cancellable {
    self = [super init];
    if (self) {
        _cancellable = cancellable;
        _isCancelled = NO;
    }
    return self;
}

- (void)cancel {
    [self.cancellable cancel];
    self.isCancelled = YES;
}

@end
