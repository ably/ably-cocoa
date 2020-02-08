//
//  ARTPluginSet.h
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTPluginType.h>

@class ARTPlugin;

NS_ASSUME_NONNULL_BEGIN

@interface NSSet (ARTPluginSet)

- (nullable Class)pluginClassOf:(ARTPluginType)pluginType;

@end

NS_ASSUME_NONNULL_END
