//
//  ARTBaseMessage.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTDataEncoder.h"
#import "ARTStatus.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage : NSObject<NSCopying>

/// A unique id for this message
@property (strong, nonatomic) NSString *id;

/// The timestamp for this message
@property (strong, nonatomic) NSDate *timestamp;

/// The id of the publisher of this message
@property (strong, nonatomic) NSString *clientId;

/// The connection id of the publisher of this message
@property (strong, nonatomic) NSString *connectionId;

/// Any transformation applied to the data for this message
@property (strong, nonatomic) NSString *encoding;

@property (strong, nonatomic) id data;

- (ARTStatus *__art_nonnull)decodeWithEncoder:(ARTDataEncoder*)encoder output:(id __art_nonnull*__art_nonnull)output;
- (ARTStatus *__art_nonnull)encodeWithEncoder:(ARTDataEncoder*)encoder output:(id __art_nonnull*__art_nonnull)output;

- (id)content;
- (NSString *)description;

- (instancetype)messageWithData:(id)data encoding:(NSString *)encoding;

@end

ART_ASSUME_NONNULL_END
