//
//  ARTProtocolMessage+Private.h
//  ably-ios
//
//  Created by Toni Cárdenas on 26/01/2016.
//  Copyright (c) 2014 Ably. All rights reserved.
//

ART_ASSUME_NONNULL_BEGIN

@interface ARTProtocolMessage ()

@property (readwrite, assign, nonatomic) BOOL hasConnectionSerial;
@property (readonly, assign, nonatomic) BOOL ackRequired;

- (BOOL)isSyncEnabled;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg;

@end

ART_ASSUME_NONNULL_END
