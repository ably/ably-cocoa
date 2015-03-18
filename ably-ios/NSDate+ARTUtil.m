//
//  NSDate+ARTUtil.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "NSDate+ARTUtil.h"

@implementation NSDate (ARTUtil)

+ (instancetype)artDateFromIntegerMs:(NSInteger)ms {
    NSTimeInterval intervalSince1970 = ms / 1000.0;
    return [NSDate dateWithTimeIntervalSince1970:intervalSince1970];
}

+ (instancetype)artDateFromNumberMs:(NSNumber *)number {
    return [self artDateFromIntegerMs:[number integerValue]];
}

- (NSNumber *)artToNumberMs {
    return [NSNumber numberWithInteger:[self artToIntegerMs]];
}

- (NSInteger)artToIntegerMs {
    return (NSInteger)round([self timeIntervalSince1970] * 1000.0);
}

-(NSString *) toIntervalFormat:(Granularity) granularity {
    /*
     public static enum Granularity {
     MINUTE,
     HOUR,
     DAY,
     MONTH
     }
     
     private static String[] intervalFormatString = new String[] {
     "yyyy-MM-dd:hh:mm",
     "yyyy-MM-dd:hh",
     "yyyy-MM-dd",
     "yyyy-MM"
     };
     
     public static String toIntervalId(long timestamp, Granularity granularity) {
     String formatString = intervalFormatString[granularity.ordinal()];
     return new SimpleDateFormat(formatString).format(new Date(timestamp));
     }
     
     public static long fromIntervalId(String intervalId) {
     try {
     String formatString = intervalFormatString[0].substring(0, intervalId.length());
     return new SimpleDateFormat(formatString).parse(intervalId).getTime();
     } catch (ParseException e) { return 0; }
     }
     */
    /*
     NSString *dateStr = @"9/8/2011 11:10:9";
     NSDateFormatter *dtF = [[NSDateFormatter alloc] init];
     [dtF setDateFormat:@"d/M/yyyy hh:mm:s"];
     NSDate *d = [dtF dateFromString:dateStr];
     NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
     [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:s"];
     NSString *st = [dateFormat stringFromDate:d];
     NSLog(@"%@",st);
     [dtF release];
     [dateFormat release];
     */
    return @"TODO";
}

@end
