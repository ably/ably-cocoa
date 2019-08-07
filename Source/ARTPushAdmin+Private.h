//
//  ARTPushAdmin+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTPushAdmin.h>

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushAdmin ()

- (instancetype)initWithRest:(ARTRestInternal *)rest;

@end

NS_ASSUME_NONNULL_END
