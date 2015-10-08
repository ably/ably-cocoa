//
//  ARTMessage.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTBaseMessage.h"

@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (readwrite, strong, nonatomic) NSString *name;

- (instancetype)initWithData:(id)data name:(NSString *)name;

@end
