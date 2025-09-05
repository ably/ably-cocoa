//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import <Foundation/Foundation.h>
#import "ARTInternalLog.h"

NS_ASSUME_NONNULL_BEGIN

// Uncomment this line to enable debug logging
//#define ARTSR_DEBUG_LOG_ENABLED

#define ARTSRErrorLog(logger, format, ...) ARTLogError(logger, @"%@", [NSString stringWithFormat:@"[SocketRocket] %@", [NSString stringWithFormat:format, ##__VA_ARGS__]])

#ifdef ARTSR_DEBUG_LOG_ENABLED
#define ARTSRDebugLog(logger, format, ...) ARTLogDebug(logger, @"%@", [NSString stringWithFormat:@"[SocketRocket] %@", [NSString stringWithFormat:format, ##__VA_ARGS__]])
#else
#define ARTSRDebugLog(logger, format, ...)
#endif

NS_ASSUME_NONNULL_END
