//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "ARTSRLog.h"
#import "ARTLog.h"

NS_ASSUME_NONNULL_BEGIN

extern void ARTSRErrorLog(ARTLog * _Nullable logger, NSString *format, ...)
{
    __block va_list arg_list;
    va_start (arg_list, format);

    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];

    va_end(arg_list);

    [logger error:@"[SocketRocket] %@", formattedString];
}

extern void ARTSRDebugLog(ARTLog * _Nullable logger, NSString *format, ...)
{
#ifdef ARTSR_DEBUG_LOG_ENABLED
    ARTSRErrorLog(logger, tag, format);
#endif
}

NS_ASSUME_NONNULL_END
