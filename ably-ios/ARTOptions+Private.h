//
//  ARTOptions+Private.h
//  ably
//
//  Created by vic on 12/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

@interface ARTOptions (Private)
{
    
}
+(NSString *) getDefaultRestHost:(NSString *) replacement modify:(bool) modify;
+(NSString *) getDefaultRealtimeHost:(NSString *) replacement modify:(bool) modify;

@end

