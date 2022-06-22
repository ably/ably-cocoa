//
// Created by Ikbal Kaya on 08/06/2022.
//

#import <Foundation/Foundation.h>
#import "ARTTokenRevocationTarget.h"
#import "ARTStatus.h"

@class ARTRevokedTarget;


@interface ARTTokenRevocationResponse : NSObject

@property(strong, nonatomic) NSArray<ARTRevokedTarget *> *revokedTargets;

@end


@interface ARTTokenRevocationBatchErrorResponse : NSObject

@property(strong, nonatomic) NSDictionary<ARTTokenRevocationTarget *, ARTErrorInfo *> *errorItems;

@end
