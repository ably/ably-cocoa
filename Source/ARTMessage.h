//
//  ARTMessage.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTBaseMessage.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (art_nullable, readwrite, strong, nonatomic) NSString *name;

- (instancetype)initWithName:(art_nullable NSString *)name data:(id)data;
- (instancetype)initWithName:(art_nullable NSString *)name data:(id)data clientId:(NSString *)clientId;

@end

ART_ASSUME_NONNULL_END
