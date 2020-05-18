//
//  XKLocation.h
//  MBB
//
//  Created by Nicholas on 2019/1/4.
//  Copyright © 2019 Nicholas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XKLocationType) {
    
    //定位城市，一次即停
    XKLocationTypeCity = 0,
};

@interface XKLocationManager : NSObject

///根据地址编译坐标
+ (void)xk_geocodeAddress:(NSString *)address completionHandler:(void(^)(CLLocation * _Nullable location, CLLocationCoordinate2D coordinate, CLPlacemark * _Nullable placemark, NSString * _Nullable city))completionHandler;

+ (instancetype)xk_manager;

- (void)xk_start;

- (void)xk_stop;

- (void)xk_setLocationAccuracy:(CLLocationAccuracy)accuracy;

@property (nonatomic, copy) void(^xk_didFinishLocation)(CLLocation *location, CLLocationCoordinate2D coordinate, CLPlacemark *placemark, NSString *city);

@property (nonatomic, copy) void(^xk_locationStatusDidChange)(CLLocationManager *manager, CLAuthorizationStatus status);

@property (nonatomic, copy) void(^xk_fail)(NSError *error);

@property (nonatomic, assign) XKLocationType type;

@end

NS_ASSUME_NONNULL_END
