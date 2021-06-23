//
//  ARTStringifiable.m
//  Ably
//
//  Created by Łukasz Szyszkowski on 21/06/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

#import "ARTStringifiable.h"
#import "ARTStringifiable+Private.h"

@implementation ARTStringifiable

- (instancetype)initWithString:(NSString *)value {
    self = [super init];
    if (self) {
        self.value = value;
    }
    return self;
}

- (instancetype)initWithNumber:(NSNumber *)value {
    self = [super init];
    if (self) {
        self.value = value;
    }
    return self;
}

- (instancetype)initWithBool:(BOOL)value {
    self = [super init];
    if (self) {
        self.value = [NSNumber numberWithBool:value];
    }
    return self;
}

- (NSString *)convert {
    if ([_value isKindOfClass:[NSString class]]) {

        return (NSString*)_value;
    } else if ([_value isKindOfClass:[NSNumber class]]) {
        if (strcmp([_value objCType], @encode(BOOL)) == 0) {
            
            return [_value boolValue] ? @"true" : @"false";
        } else if (
                   strcmp([_value objCType], @encode(double)) == 0 ||
                   strcmp([_value objCType], @encode(float)) == 0 ||
                   strcmp([_value objCType], @encode(NSInteger)) == 0
                   ) {
            
            return [(NSNumber*)_value stringValue];
        } else {
            
            @throw [NSException
                    exceptionWithName:@"Can't convert value"
                    reason:[NSString stringWithFormat:@"Type %@ is not supported", [_value class]]
                    userInfo:nil];
        }
    } else {
        
        @throw [NSException
                exceptionWithName:@"Can't convert value"
                reason:[NSString stringWithFormat:@"Type %@ is not supported", [_value class]]
                userInfo:nil];
    }
}

+ (ARTStringifiable *)withString:(NSString *)value {
    return [[ARTStringifiable alloc] initWithString:value];
}

+ (ARTStringifiable *)withNumber:(NSNumber *)value {
    return [[ARTStringifiable alloc] initWithNumber:value];
}

+ (ARTStringifiable *)withBool:(BOOL)value {
    return [[ARTStringifiable alloc] initWithBool:value];
}

@end
