//
//  NawabariViewController.h
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/04.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface NawabariViewController : UIViewController <CLLocationManagerDelegate, GMSMapViewDelegate> {
	// ロケーションマネージャー
	CLLocationManager* locationManager;
    
	// 現在位置記録用
	CLLocationDegrees _longitude;
	CLLocationDegrees _latitude;
    
    // Google Map View
    GMSMapView *mapView_;
    
    // 最初に現在地を取得した時だけloadViewを呼び出すため
    _Bool isFirstLoad;
}

@end
