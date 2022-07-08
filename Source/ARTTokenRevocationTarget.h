//
// Created by Ikbal Kaya on 07/06/2022.
//

#import <Foundation/Foundation.h>


@interface ARTTokenRevocationTarget : NSObject
@property(strong, nonatomic) NSString *type;
@property(strong, nonatomic) NSString *value;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWith:(NSString *)type value:(NSString *)value;

@end