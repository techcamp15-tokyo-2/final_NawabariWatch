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
    GMSMapView* mapView_;
    
    // なわばり
    GMSCircle* circ;
    
    // なわばりの合計
    CGFloat nawabariSum;
}

- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;
- (void)loadView;
- (void)drawNawabari;
- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface NawabariViewController (Location)
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
@end
