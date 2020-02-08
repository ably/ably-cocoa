//
//  ARTPluginType.h
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTPluginType) {
    ARTPluginTypeVCDiff,
};

NSString *_Nonnull ARTPluginTypeToStr(ARTPluginType pluginType);

NS_ASSUME_NONNULL_END
