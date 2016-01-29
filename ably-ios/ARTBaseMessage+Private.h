//
//  ARTBaseMessage+Private.h
//  ably
//
//  Created by Toni Cárdenas on 29/1/16.
//  Copyright © 2016 Ably. All rights reserved.
//

//
//  ARTBaseMessage.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "CompatibilityMacros.h"
#import "ARTBaseMessage.h"
#import "ARTDataEncoder.h"
#import "ARTStatus.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage ()

- (ARTStatus *__art_nonnull)decodeWithEncoder:(ARTDataEncoder*)encoder output:(id __art_nonnull*__art_nonnull)output;
- (ARTStatus *__art_nonnull)encodeWithEncoder:(ARTDataEncoder*)encoder output:(id __art_nonnull*__art_nonnull)output;

@end

ART_ASSUME_NONNULL_END
