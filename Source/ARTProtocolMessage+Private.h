//
//  ARTProtocolMessage+Private.h
//  ably-ios
//
//  Created by Toni Cárdenas on 26/01/2016.
//  Copyright (c) 2014 Ably. All rights reserved.
//

/// ARTProtocolMessageFlag bitmask
typedef NS_OPTIONS(NSUInteger, ARTProtocolMessageFlag) {
    ARTProtocolMessageFlagHasPresence = (1UL << 0), //1
    ARTProtocolMessageFlagHasBacklog = (1UL << 1), //2
    ARTProtocolMessageFlagResumed = (1UL << 2) //4
};

ART_ASSUME_NONNULL_BEGIN

@interface ARTProtocolMessage ()

@property (readwrite, assign, nonatomic) BOOL hasConnectionSerial;
@property (readonly, assign, nonatomic) BOOL ackRequired;

@property (readonly, assign, nonatomic) BOOL hasPresence;
@property (readonly, assign, nonatomic) BOOL hasBacklog;
@property (readonly, assign, nonatomic) BOOL resumed;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg;

@end

ART_ASSUME_NONNULL_END
