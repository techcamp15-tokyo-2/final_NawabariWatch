//
//  NawabariViewController.m
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/04.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "NawabariViewController.h"

@implementation NawabariViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	_longitude = 0.0;
	_latitude = 0.0;
    isFirstLoad = YES;
    
	// ロケーションマネージャーを作成
	BOOL locationServicesEnabled;
	locationManager = [[CLLocationManager alloc] init];
	if ([CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]) {
		// iOS4.0以降はクラスメソッドを使用
		locationServicesEnabled = [CLLocationManager locationServicesEnabled];
	} else {
		// iOS4.0以前はプロパティを使用
		locationServicesEnabled = locationManager.locationServicesEnabled;
	}
    
	if (locationServicesEnabled) {
		locationManager.delegate = self;
        
		// 位置情報取得開始
		[locationManager startUpdatingLocation];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 位置情報が取得成功した場合にコールされる
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	// 位置情報更新
	_longitude = newLocation.coordinate.longitude;
	_latitude = newLocation.coordinate.latitude;
    
    if (isFirstLoad) {
        isFirstLoad = FALSE;
        [self loadView];
    }
}

// 位置情報が取得失敗した場合にコールされる。
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (error) {
		NSString* message = nil;
		switch ([error code]) {
                // アプリでの位置情報サービスが許可されていない場合
			case kCLErrorDenied:
				// 位置情報取得停止
				[locationManager stopUpdatingLocation];
				message = [NSString stringWithFormat:@"このアプリは位置情報サービスが許可されていません。"];
				break;
			default:
				message = [NSString stringWithFormat:@"位置情報の取得に失敗しました。"];
				break;
		}
		if (message) {
			// アラートを表示
			UIAlertView* alert=[[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil
                                                 cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
}

-(void)loadView {
    // Do any additional setup after loading the view, typically from a nib.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_latitude
                                                            longitude:_longitude
                                                                 zoom:12];
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.delegate = self;
    mapView_.myLocationEnabled = YES;
    mapView_.settings.myLocationButton = YES;
    self.view = mapView_;
    
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(_latitude, _longitude);
    //    marker.icon = [UIImage imageNamed:@"tokyo_tower64"];
    marker.title = [NSString stringWithFormat:@"longitude%f",_longitude];
    marker.snippet = [NSString stringWithFormat:@"latitude%f",_latitude];
    marker.map = mapView_;
    
    [self drawNawabari];
}

// なわばり(markerのまわりの円)を描く
-(void)drawNawabari {
    CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(_latitude, _longitude);
    GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:1000];
    circ.fillColor   = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
    circ.strokeColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0];
    circ.map = mapView_;
}

/*
(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(id)marker {
    // infoWindowを作る
    UIView *infoWindow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 40)];
    infoWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(4, 2, 96, 20);
    titleLabel.font  = [UIFont boldSystemFontOfSize:18];
    titleLabel.text  = [marker title];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
    [infoWindow addSubview:titleLabel];

    UILabel *snippetLabel = [[UILabel alloc] init];
    snippetLabel.frame = CGRectMake(4, 24, 96, 14);
    snippetLabel.font  = [UIFont boldSystemFontOfSize:12];
    snippetLabel.text  = [marker snippet];
    snippetLabel.textColor = [UIColor whiteColor];
    snippetLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
    [infoWindow addSubview:snippetLabel];
 
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    btn.frame = CGRectMake(100, 0, 40, 40);
    [infoWindow addSubview:btn];

    return infoWindow;
}
*/

-(void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker {
    NSString* message = [NSString stringWithFormat:@"チェックインしますか?"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"title" message:message delegate:self
                                        cancelButtonTitle:@"キャンセル" otherButtonTitles:@"チェックイン", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            NSLog(@"ここでチェックインの処理");
            break;
        default:
            break;
    }
}
@end
