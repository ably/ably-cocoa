//
//  ARTPropertyListFileStorage.m
//  Ably
//
//  Created by Lawrence Forooghian on 25/01/2022.
//  Copyright © 2022 Ably. All rights reserved.
//

#import "ARTPropertyListFileStorage.h"
#import "ARTStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTPropertyListFileStorage()

@property (nonatomic, strong) NSURL *propertyListFileURL;

@end

NS_ASSUME_NONNULL_END

@implementation ARTPropertyListFileStorage

- (instancetype)initWithPropertyListFileURL:(NSURL *)propertyListFileURL {
    if (self = [super init]) {
        _propertyListFileURL = propertyListFileURL;
    }
    
    return self;
}

+ (NSURL *)defaultPropertyListFileURL {
    NSURL *applicationSupportDirectoryURL = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask][0];
    
    return [applicationSupportDirectoryURL URLByAppendingPathComponent:@"io.ably.Ably/Storage.plist"];
}

- (nullable NSDictionary *)loadPropertyList:(NSError **)error {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.propertyListFileURL.path]) {
        return [[NSDictionary alloc] init];
    }
    
    NSData *const data = [NSData dataWithContentsOfURL:self.propertyListFileURL options:0 error:error];
    
    if (!data) {
        return nil;
    }
    
    const id topLevelObject = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:error];
    
    if (!topLevelObject) {
        return nil;
    }
    
    if (![topLevelObject isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:ARTAblyErrorDomain code:ARTClientCodeErrorStorageIsNotDictionary userInfo:nil];
        }
        return nil;
    }
    
    return topLevelObject;
}

- (BOOL)savePropertyList:(id)propertyList error:(NSError **)error {
    NSData *const data = [NSPropertyListSerialization dataWithPropertyList:propertyList format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    
    if (!data) {
        return NO;
    }
    
    if (![self ensureDirectoryExists:error]) {
        return NO;
    }
    
    return [data writeToURL:self.propertyListFileURL atomically:YES];
}

- (BOOL)ensureDirectoryExists:(NSError **)error {
    NSURL *const directoryURL = [self.propertyListFileURL URLByDeletingLastPathComponent];
    
    NSFileManager *const fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:directoryURL.path]) {
        return YES;
    }
    
    if (![fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:error]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)getObject:(id  _Nullable __autoreleasing *)ptr forKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSDictionary *const propertyList = [self loadPropertyList:error];
    
    if (!propertyList) {
        return NO;
    }
    
    if (ptr) {
        *ptr = [propertyList objectForKey:key];
    }
    return YES;
}

- (BOOL)setObject:(id)value forKey:(NSString *)key error:(NSError **)error {
    NSMutableDictionary *propertyList = [[self loadPropertyList:error] mutableCopy];
    
    if (!propertyList) {
        return NO;
    }
    
    [propertyList setValue:value forKey:key];
    
    return [self savePropertyList:propertyList error:error];
}

@end
