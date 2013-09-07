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
#import "Foursquare.h"

@interface NawabariViewController : UIViewController <CLLocationManagerDelegate, FoursquareDelegate> {
	// ロケーションマネージャー
	CLLocationManager* locationManager;
    
    //foursquare
    Foursquare *foursquare;
    
	// 現在位置記録用
	CLLocationDegrees _longitude;
	CLLocationDegrees _latitude;
    
    GMSMapView *mapView_;
}
@property(nonatomic,readonly,strong) Foursquare *foursquare;
- (void)requestDidSending;
@end