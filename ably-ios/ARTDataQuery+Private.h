//
//  ARTDataQuery+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTDataQuery.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTDataQuery(Private)

- (NSMutableArray /* <NSURLQueryItem *> */ *)asQueryItems;

@end

ART_ASSUME_NONNULL_END
