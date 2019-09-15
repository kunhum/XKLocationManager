//
//  XKLocation.m
//  MBB
//
//  Created by Nicholas on 2019/1/4.
//  Copyright © 2019 Nicholas. All rights reserved.
//

#import "XKLocationManager.h"

@interface XKLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation XKLocationManager

+ (instancetype)xk_manager {
    return [self new];
}

- (instancetype)init {
    if (self = [super init]) {
        
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        //定位城市精度不需要太准确，保证速度
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    }
    return self;
}

#pragma mark 开始定位
- (void)xk_start {
    
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
        
        [self.locationManager startUpdatingLocation];
    }
    //用户拒绝
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        Class class = NSClassFromString(@"SVProgressHUD");
        if (class) {
            [class performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];
        }
        [self showAlert];
    }
    else {
        
        [self.locationManager requestWhenInUseAuthorization];
        
    }
    
}
- (void)xk_stop {
    [self.locationManager stopUpdatingLocation];
}

- (void)xk_setLocationAccuracy:(CLLocationAccuracy)accuracy {
    self.locationManager.desiredAccuracy = accuracy;
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
//    NSLog(@"在定位");
    CLLocation *location = locations.lastObject;
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    CLGeocoder *geocoder = [CLGeocoder new];
    //反编译地址
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        CLPlacemark *placemark = placemarks.firstObject;
        if (placemark) {
            //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
            NSString *city = placemark.locality;
            
            if (!city) {
                city = placemark.administrativeArea;
            }
            
            !self.xk_didFinishLocation ?: self.xk_didFinishLocation(location, coordinate, placemark, city);
        }
        else {
            !self.xk_fail ?: self.xk_fail(error);
        }
        
    }];
    
    if (self.type == XKLocationTypeCity) {
        [self xk_stop];
    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (error.code == kCLErrorDenied) {
        [self showAlert];
    }
    
    
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        
        [self xk_start];
    }
    else {
        [self xk_stop];
    }
}

#pragma mark 根据地址编辑坐标
+ (void)xk_geocodeAddress:(NSString *)address completionHandler:(void (^)(CLLocation * _Nonnull, CLLocationCoordinate2D, CLPlacemark * _Nonnull, NSString * _Nonnull))completionHandler {
    
    CLGeocoder *geocoder = [CLGeocoder new];
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        CLPlacemark *placemark = placemarks.firstObject;
        if (placemark) {
            //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
            NSString *city = placemark.locality;
            
            if (!city) {
                city = placemark.administrativeArea;
            }
            
            !completionHandler ?: completionHandler(placemark.location, placemark.location.coordinate, placemark, city);
        }
        else {
            !completionHandler ?: completionHandler(nil, CLLocationCoordinate2DMake(0, 0), nil, nil);
            
        }
    }];
    
    
}

#pragma mark 提示用户
- (void)showAlert {
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = appInfo[@"CFBundleDisplayName"];
    NSString *title = [NSString stringWithFormat:@"%@需要访问您的位置",appName];
    UIAlertController *alcrtC = [UIAlertController alertControllerWithTitle:nil message:title preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *goAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self xk_stop];
    }];
    [alcrtC addAction:cancelAction];
    [alcrtC addAction:goAction];
    
    [[self xk_currentViewController] presentViewController:alcrtC animated:YES completion:nil];
}
- (UIViewController *)xk_currentViewController {

    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findBestViewController:viewController];
}

- (UIViewController *)findBestViewController:(UIViewController *)vc {
    if (vc.presentedViewController) {
        // Return presented view controller
        return [self findBestViewController:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        // Return right hand side
        UISplitViewController *svc = (UISplitViewController *)vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.viewControllers.lastObject];
        else
            return vc;
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        // Return top view
        UINavigationController *svc = (UINavigationController *)vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.topViewController];
        else
            return vc;
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // Return visible view
        UITabBarController *svc = (UITabBarController *)vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.selectedViewController];
        else
            return vc;
    } else {
        // Unknown view controller type, return last child view controller
        return vc;
    }
}



@end
