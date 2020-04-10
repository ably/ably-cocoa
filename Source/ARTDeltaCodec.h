//
//  ARTDeltaCodec.h
//  Ably
//
//  Created by Ricardo Pereira on 08/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import <Ably/ARTVCDiffDecoder.h>
#import <AblyDeltaCodec/AblyDeltaCodec.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDeltaCodec (ARTDeltaCodec_VCDiffDecoder) <ARTVCDiffDecoder>
@end

NS_ASSUME_NONNULL_END
