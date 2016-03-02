//
//  ARTJsonEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTEncoder.h"

@class ARTLog;

@interface ARTJsonEncoder : NSObject <ARTEncoder>

@property (nonatomic, weak) ARTLog *logger;

- (instancetype)initWithLogger:(ARTLog *)logger;

@end
