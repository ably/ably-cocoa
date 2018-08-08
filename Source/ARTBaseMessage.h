//
//  ARTBaseMessage.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage : NSObject<NSCopying>

/// A unique id for this message
@property (nullable, strong, nonatomic) NSString *id;

/// The timestamp for this message
@property (strong, nonatomic, nullable) NSDate *timestamp;

/// The id of the publisher of this message
@property (strong, nonatomic, nullable) NSString *clientId;

/// The connection id of the publisher of this message
@property (strong, nonatomic) NSString *connectionId;

/// Any transformation applied to the data for this message
@property (strong, nonatomic, nullable) NSString *encoding;

@property (strong, nonatomic, nullable) id data;

/// The event name, if available
@property (nullable, readwrite, strong, nonatomic) NSString *name;
@property (nullable, nonatomic) id<ARTJsonCompatible> extras;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
