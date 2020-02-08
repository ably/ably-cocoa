//
//  ARTPluginType.m
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import "ARTPluginType.h"

NSString *ARTPluginTypeToStr(ARTPluginType pluginType) {
    switch (pluginType) {
        case ARTPluginTypeVCDiff:
            return @"vcdiff"; //0
    }
}
