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
    
    // markerを表示するかどうかのフラグ
    BOOL isDisplayMarker;
    
    // 自分のなわばりとなっているvenueのIDの集合
    NSMutableSet* nawabariVenueIds;
    // なわばり(マーカーと領土のArray)
    NSMutableArray* nawabaris;
    // なわばりの合計面積
    CGFloat nawabariAreaSum;
    // なわばり面積のラベル
    UILabel *areaLabel;
    
    // 近郊の自分のじゃないなわばり(マーカーと領土のArray)
    NSMutableArray* surroundingNawabaris;
    
    // 選択されたチェックイン待ちのvenue
    NSString *tappedVenueId;
    
    // 領土表示ボタン
    UIButton *areaInfoWindowButton;
    // ランキング表示ボタン
    UIButton *rankInfoWindowButton;
    // venueを探すボタン
    UIButton *searchButton;
    
    // テキストの色
    UIColor *textColorBlack;
    // テキストラベルの背景の色
    UIColor *backgroundColorWhite;
    UIColor *backgroundColorBlack;
    
    // rank viewの5つのボタンを格納するArray
    NSMutableArray *rankDisplayButtonArray;
    
    // MAPに戻るボタン
    UIButton *backToMapButton;
    // rankView
    UIView *rankView;
    
    //最初の一回だけ位置が更新されたら再描画する
    BOOL isFirst;
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
- (void)drawRankInfoWindowById:(NSString *)userId Name:(NSString *)userName;
- (NSDictionary *)getRankAndUsersNumById:(NSString *)userId andTerritory:(double)territory;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface NawabariViewController (Location)
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
@end

enum {
    startAuthorization = 0,
    requestCheckin,
    finishCheckin
};
