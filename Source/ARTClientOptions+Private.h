//
//  ARTClientOptions+Private.h
//  ably
//
//  Created by Toni Cárdenas on 24/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTClientOptions.h>

@interface ARTClientOptions ()

@property (nullable, strong, nonatomic) NSString *channelNamePrefix;

/**
 Specific client library features that are not commonly used may be supplied as independent libraries.
 */
@property (nullable, nonatomic, copy) NSSet<ARTPlugin *> *plugins;

+ (void)setDefaultEnvironment:(NSString *_Nullable)environment;
+ (BOOL)getDefaultIdempotentRestPublishingForVersion:(NSString *_Nonnull)version;
- (NSURLComponents *_Nonnull)restUrlComponents;

@end
