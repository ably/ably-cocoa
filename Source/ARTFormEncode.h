//
//  ARTFormEncode.h
//  Ably
//
//  Created by Ricardo Pereira on 27/09/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Express the input dictionary as a `application/x-www-form-urlencoded` string.
 If the parameters dictionary is nil or empty, returns nil.
*/
NSString *ARTFormEncode(NSDictionary *parameters);

NS_ASSUME_NONNULL_END
