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

@interface ARTDataEncoderOutput : NSObject

@property (readonly, nonatomic, art_nullable) id data;
@property (readonly, nonatomic, art_nullable) NSString *encoding;
@property (readonly, nonatomic, art_nullable) ARTErrorInfo *errorInfo;

- initWithData:(id __art_nullable)data encoding:(NSString *__art_nullable)encoding errorInfo:(ARTErrorInfo *__art_nullable)errorInfo;

@end

@interface ARTDataEncoder : NSObject 

- (instancetype)initWithCipherParams:(ARTCipherParams *__art_nullable)params error:(NSError *__art_nullable*__art_nullable)error;
- (ARTDataEncoderOutput *)encode:(id __art_nullable)data;
- (ARTDataEncoderOutput *)decode:(id __art_nullable)data encoding:(NSString *__art_nullable)encoding;

@end

@interface NSString (ARTDataEncoder)

+ (NSString *)artAddEncoding:(NSString *)encoding toString:(NSString *__art_nullable)s;
- (NSString *)artLastEncoding;
- (NSString *)artRemoveLastEncoding;

@end

ART_ASSUME_NONNULL_END
