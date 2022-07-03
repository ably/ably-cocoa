#import <Foundation/Foundation.h>

@class ARTErrorInfo;
@class ARTDeviceDetails;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDevicePushStatus : NSObject

@property (strong, nullable, nonatomic) NSString *state;
@property (strong, nullable, nonatomic) ARTErrorInfo *errorReason;

- (instancetype)init;

@end

@interface ARTDeviceDetailsResponse : NSObject

@property (nonatomic) ARTDeviceDetails *deviceDetails;
@property (nonatomic, nullable) ARTDevicePushStatus *pushStatus;

@end

NS_ASSUME_NONNULL_END
