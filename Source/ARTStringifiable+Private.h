//
//  ARTStringifiable+Private.h
//  Ably
//
//  Created by Łukasz Szyszkowski on 21/06/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTStringifiable()

- (_Nonnull instancetype)initWithString:(nonnull NSString *)value;
- (_Nonnull instancetype)initWithNumber:(nonnull NSNumber *)value;
- (_Nonnull instancetype)initWithBool:(BOOL)value;

@property(nonnull, nonatomic, strong) id value;

@end
