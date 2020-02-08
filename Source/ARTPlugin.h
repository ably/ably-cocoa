//
//  ARTPlugin.h
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTPluginType.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTPlugin : NSObject<NSCopying>

@property (nonatomic, assign) ARTPluginType pluginType;
@property (nonatomic, readwrite, strong) Class pluginClass;

- (instancetype)initWithType:(ARTPluginType)pluginType pluginClass:(Class)pluginClass;
+ (instancetype)newWithType:(ARTPluginType)pluginType pluginClass:(Class)pluginClass;

@end

NS_ASSUME_NONNULL_END
