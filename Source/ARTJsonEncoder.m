//
//  ARTJsonEncoder.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTJsonEncoder.h"

@implementation ARTJsonEncoder

- (NSString *)mimeType {
    return @"application/json";
}

- (ARTEncoderFormat)format {
    return ARTEncoderFormatJson;
}

- (NSString *)formatAsString {
    return @"json";
}

- (id)decode:(NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSData *)encode:(id)obj {
    return [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
}

@end
