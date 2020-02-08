//
//  ARTPlugin.m
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import "ARTPlugin.h"

@implementation ARTPlugin

- (instancetype)initWithType:(ARTPluginType)pluginType pluginClass:(Class)pluginClass {
    if (self = [super init]) {
        _pluginType = pluginType;
        _pluginClass = pluginClass;
    }
    return self;
}

+ (instancetype)newWithType:(ARTPluginType)pluginType pluginClass:(Class)pluginClass {
    return [[self alloc] initWithType:pluginType pluginClass:pluginClass];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTPlugin *plugin = [[[self class] allocWithZone:zone] init];
    plugin->_pluginType = self.pluginType;
    plugin->_pluginClass = self.pluginClass;
    return plugin;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" pluginType: %@,\n", ARTPluginTypeToStr(self.pluginType)];
    [description appendFormat:@" pluginClass: %@\n", self.pluginClass];
    [description appendFormat:@"}"];
    return description;
}

- (BOOL)isEqualToPlugin:(ARTPlugin *)plugin {
    if (!plugin) {
        return NO;
    }

    BOOL haveEqualPluginType = (!self.pluginType && !plugin.pluginType);

    return haveEqualPluginType;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ARTPlugin class]]) {
        return NO;
    }

    return [self isEqualToPlugin:(ARTPlugin *)object];
}

- (NSUInteger)hash {
    return [@(self.pluginType) hash];
}

@end
