//
// Created by Ikbal Kaya on 08/06/2022.
//

#import <Foundation/Foundation.h>

@class ARTRevokedTarget;


@interface ARTTokenRevocationResponse : NSObject

@property(strong, nonatomic) NSArray<ARTRevokedTarget *> *revokedTargets;

@end