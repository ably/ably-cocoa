
//
//  ARTRestChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRestChannel.h"

@interface ARTRestChannel (Private)

@property (readonly, getter=getBasePath) NSString *basePath;

@end
