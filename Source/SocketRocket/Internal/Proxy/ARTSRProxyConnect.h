//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import <Foundation/Foundation.h>

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ARTSRProxyConnectCompletion)(NSError *_Nullable error,
                                        NSInputStream *_Nullable readStream,
                                        NSOutputStream *_Nullable writeStream);

@interface ARTSRProxyConnect : NSObject

- (instancetype)initWithURL:(NSURL *)url logger:(nullable ARTLog *)logger;

- (void)openNetworkStreamWithCompletion:(ARTSRProxyConnectCompletion)completion;

@end

NS_ASSUME_NONNULL_END
