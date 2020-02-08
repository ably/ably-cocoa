//
//  ARTPluginSet.m
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import "ARTPluginSet.h"
#import "ARTPlugin.h"

@implementation NSSet (ARTPluginSet)

- (Class)pluginClassOf:(ARTPluginType)pluginType {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pluginType == %lu", (unsigned long)pluginType];
    ARTPlugin *plugin = [self filteredSetUsingPredicate:predicate].allObjects.lastObject;
    return plugin.pluginClass;
}

@end
