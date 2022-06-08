//
// Created by Ikbal Kaya on 08/06/2022.
//

#import <Foundation/Foundation.h>

@class ARTTokenRevocationTarget;


@interface ARTRevokedTarget : NSObject
@property (strong, nonatomic) ARTTokenRevocationTarget *target;
@property (strong, nonatomic) NSDate *issuedBefore;
@property (strong, nonatomic) NSDate *appliesAt;
@end