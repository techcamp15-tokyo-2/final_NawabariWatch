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
#import "FoursquareAPI.h"

@interface NawabariViewController : UIViewController <CLLocationManagerDelegate, FoursquareAPIDelegate> {
    // ロケーションマネージャー
	CLLocationManager* locationManager;
    
	// 現在位置記録用
	CLLocationDegrees longitude_;
	CLLocationDegrees latitude_;
    
    // Google Map View
    GMSMapView* mapView_;
    
    //foursquareAPI
    FoursquareAPI *foursquareAPI;
    
    // なわばり(マーカーと領土のArray)
    NSMutableArray* nawabaris;
    
    // なわばりの合計面積
    CGFloat nawabariAreaSum;
    
    // なわばり面積のラベル
    UILabel *areaLabel;
    
    // 選択されたチェックイン待ちのvenue
    NSString *tappedVenueId;
}

@property(nonatomic,readonly,strong) FoursquareAPI *foursquareAPI;

- (void)viewDidLoad;
- (void)didReceiveMemoryWarning;

- (void)didAuthorize;
- (void)getVenueHistory:(NSDictionary *)response;
- (void)getSearchVenues:(NSDictionary *)response;
- (void)getCheckin:(NSDictionary *)response;

- (void)loadView;
- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(id)marker;
- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker;
- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position;

- (void)drawNawabaris:(NSArray *)venues;
- (void)drawSurroundingNawabaris:(NSArray *)venues;
- (void)drawAreaInfoWindow;
- (void)drawRankInfoWindow;
- (NSDictionary *)getRankAndUsersNumById:(int)id andTerritory:(double)territory;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface NawabariViewController (Location)
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
@end
