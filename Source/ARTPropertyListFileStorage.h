//
//  ARTPropertyListFileStorage.h
//  Ably
//
//  Created by Lawrence Forooghian on 25/01/2022.
//  Copyright © 2022 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// TODO we need to make sure access to this is synchronised - across instances and across threads on single instance
@interface ARTPropertyListFileStorage : NSObject

+ (NSURL *)defaultPropertyListFileURL;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPropertyListFileURL:(NSURL *)propertyListFileURL;

- (BOOL)getObject:(_Nullable id * _Nullable)ptr forKey:(NSString *)key error:(NSError **)error;
- (BOOL)setObject:(nullable id)value forKey:(NSString *)key error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
