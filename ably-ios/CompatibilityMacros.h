//
//  CompatibilityMacros.h
//  ably
//
//  Created by Yavor Georgiev on 1.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//

#ifndef CompatibilityMacros_h
#define CompatibilityMacros_h

#if __has_feature(nullability)
    #define __ART_ASSUME_NONNULL_BEGIN      NS_ASSUME_NONNULL_BEGIN
    #define __ART_ASSUME_NONNULL_END        NS_ASSUME_NONNULL_END
    #define __ART_NULLABLE                  nullable
#else
    #define __ART_ASSUME_NONNULL_BEGIN
    #define __ART_ASSUME_NONNULL_END
    #define __ART_NULLABLE
#endif

#if __has_feature(objc_generics)
    #define __GENERIC(class, ...)      class<__VA_ARGS__>
#else
    #define __GENERIC(class, ...)      class
#endif

#endif /* CompatibilityMacros_h */
