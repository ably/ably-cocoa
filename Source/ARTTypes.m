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

uint64_t dateToMilliseconds(NSDate *date) {
    return (uint64_t)(date.timeIntervalSince1970 * 1000);
}

uint64_t timeIntervalToMilliseconds(NSTimeInterval seconds) {
    return (uint64_t)(seconds * 1000);
}

NSTimeInterval millisecondsToTimeInterval(uint64_t msecs) {
    return ((NSTimeInterval)msecs) / 1000;
}

NSString *generateNonce() {
    // Generate two random numbers up to 8 digits long and concatenate them to produce a 16 digit random number
    NSUInteger r1 = arc4random_uniform(100000000);
    NSUInteger r2 = arc4random_uniform(100000000);
    return [NSString stringWithFormat:@"%08lu%08lu", (long)r1, (long)r2];
}

#pragma mark - ARTConnectionStateChange

@implementation ARTConnectionStateChange

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current previous:(ARTRealtimeConnectionState)previous reason:(ARTErrorInfo *)reason {
    return [self initWithCurrent:current previous:previous reason:reason retryIn:(NSTimeInterval)0];
}

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current previous:(ARTRealtimeConnectionState)previous reason:(ARTErrorInfo *)reason retryIn:(NSTimeInterval)retryIn {
    self = [self init];
    if (self) {
        _current = current;
        _previous = previous;
        _reason = reason;
        _retryIn = retryIn;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t current: %@; \n\t previous: %@; \n\t reason: %@; \n\t retryIn: %f; \n", [super description], ARTRealtimeConnectionStateToStr(_current), ARTRealtimeConnectionStateToStr(_previous), _reason, _retryIn];
}

- (void)setRetryIn:(NSTimeInterval)retryIn {
    _retryIn = retryIn;
}

@end

NSString *ARTRealtimeConnectionStateToStr(ARTRealtimeConnectionState state) {
    switch(state) {
        case ARTRealtimeInitialized:
            return @"Initialized"; //0
        case ARTRealtimeConnecting:
            return @"Connecting"; //1
        case ARTRealtimeConnected:
            return @"Connected"; //2
        case ARTRealtimeDisconnected:
            return @"Disconnected"; //3
        case ARTRealtimeSuspended:
            return @"Suspended"; //4
        case ARTRealtimeClosing:
            return @"Closing"; //5
        case ARTRealtimeClosed:
            return @"Closed"; //6
        case ARTRealtimeFailed:
            return @"Failed"; //7
    }
}

NSString *ARTRealtimeConnectionEventToStr(ARTRealtimeConnectionEvent event) {
    switch(event) {
        case ARTRealtimeConnectionEventInitialized:
            return @"Initialized"; //0
        case ARTRealtimeConnectionEventConnecting:
            return @"Connecting"; //1
        case ARTRealtimeConnectionEventConnected:
            return @"Connected"; //2
        case ARTRealtimeConnectionEventDisconnected:
            return @"Disconnected"; //3
        case ARTRealtimeConnectionEventSuspended:
            return @"Suspended"; //4
        case ARTRealtimeConnectionEventClosing:
            return @"Closing"; //5
        case ARTRealtimeConnectionEventClosed:
            return @"Closed"; //6
        case ARTRealtimeConnectionEventFailed:
            return @"Failed"; //7
        case ARTRealtimeConnectionEventUpdate:
            return @"Update"; //8
    }
}

@implementation NSString (ARTJsonCompatible)

- (NSDictionary *)toJSON:(NSError *__art_nullable *__art_nullable)error {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
        if (error) {
            *error = jsonError;
        }
        return nil;
    }
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:ARTAblyErrorDomain code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"expected JSON object, got %@", [json class]]}];
        }
        return nil;
    }
    return (NSDictionary *)json;
}

@end

@implementation NSDictionary (ARTJsonCompatible)

- (NSDictionary *)toJSON:(NSError *__art_nullable *__art_nullable)error {
    if (error) {
        *error = nil;
    }
    return self;
}

@end

@implementation NSURL (ARTLog)

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", self.absoluteString];
}

@end

NSString *ARTRealtimeChannelStateToStr(ARTRealtimeChannelState state) {
    switch(state) {
        case ARTRealtimeChannelInitialized:
            return @"Initialized"; //0
        case ARTRealtimeChannelAttaching:
            return @"Attaching"; //1
        case ARTRealtimeChannelAttached:
            return @"Attached"; //2
        case ARTRealtimeChannelDetaching:
            return @"Detaching"; //3
        case ARTRealtimeChannelDetached:
            return @"Detached"; //4
        case ARTRealtimeChannelFailed:
            return @"Failed"; //5
    }
}

NSString *ARTChannelEventToStr(ARTChannelEvent event) {
    switch(event) {
        case ARTChannelEventInitialized:
            return @"Initialized"; //0
        case ARTChannelEventAttaching:
            return @"Attaching"; //1
        case ARTChannelEventAttached:
            return @"Attached"; //2
        case ARTChannelEventDetaching:
            return @"Detaching"; //3
        case ARTChannelEventDetached:
            return @"Detached"; //4
        case ARTChannelEventFailed:
            return @"Failed"; //5
        case ARTChannelEventUpdate:
            return @"Update"; //6
    }
}
