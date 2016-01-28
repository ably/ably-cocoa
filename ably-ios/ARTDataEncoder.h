//
//  ARTDataEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTStatus.h"
#import "ARTCrypto.h"

@class ARTCipherParams;

ART_ASSUME_NONNULL_BEGIN

@interface ARTDataEncoder : NSObject 

- (instancetype)initWithCipherParams:(ARTCipherParams *)params logger:(ARTLog *)logger;
- (ARTStatus *__art_nullable)encode:(id)data outputData:(id __art_nullable *__art_nonnull)outputData outputEncoding:(NSString *__art_nullable *__art_nonnull)outputEncoding;
- (ARTStatus *__art_nullable)decode:(id)data encoding:(NSString *)encoding outputData:(id __art_nullable *__art_nonnull)outputData outputEncoding:(NSString *__art_nullable *__art_nonnull)outputEncoding;

@end

@interface NSString (ARTDataEncoder)

- (NSString *)artAddEncoding:(NSString *)encoding;
- (NSString *)artLastEncoding;
- (NSString *)artRemoveLastEncoding;

@end

ART_ASSUME_NONNULL_END
