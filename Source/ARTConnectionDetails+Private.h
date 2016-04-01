//
//  ARTConnectionDetails+Private.h
//  Ably
//
//  Created by Ricardo Pereira on 24/3/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTConnectionDetails.h"
#import "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTConnectionDetails ()

@property (readwrite, strong, nonatomic, art_nullable) NSString *clientId;
@property (readwrite, strong, nonatomic, art_nullable) NSString *connectionKey;

@end

ART_ASSUME_NONNULL_END
