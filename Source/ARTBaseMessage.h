//
//  ARTBaseMessage.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage : NSObject<NSCopying>

/// A unique id for this message
@property (strong, nonatomic) NSString *id;

/// The timestamp for this message
@property (strong, nonatomic, art_nullable) NSDate *timestamp;

/// The id of the publisher of this message
@property (strong, nonatomic, art_nullable) NSString *clientId;

/// The connection id of the publisher of this message
@property (strong, nonatomic) NSString *connectionId;

/// Any transformation applied to the data for this message
@property (strong, nonatomic, art_nullable) NSString *encoding;

@property (strong, nonatomic, art_nullable) id data;

- (NSString *)description;

@end

ART_ASSUME_NONNULL_END
