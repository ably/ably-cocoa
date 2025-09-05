//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSData *ARTSRSHA1HashFromString(NSString *string);
extern NSData *ARTSRSHA1HashFromBytes(const char *bytes, size_t length);

extern NSString *ARTSRBase64EncodedStringFromData(NSData *data);

NS_ASSUME_NONNULL_END
