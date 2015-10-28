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

NSString *encodeBase64(NSString *value) {
    return [[value dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

NSString *decodeBase64(NSString *base64) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

uint64_t dateToMiliseconds(NSDate *date) {
    return (uint64_t)(date.timeIntervalSince1970 * 1000);
}

uint64_t timeIntervalToMiliseconds(NSTimeInterval seconds) {
    return (uint64_t)(seconds * 1000);
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
