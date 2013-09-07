//
//  NawabariViewController.m
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/04.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "NawabariViewController.h"
#import "NawabariViewController+Location.m"

@implementation NawabariViewController 
@synthesize foursquare = foursquare;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //foursquareの汎用クラスを作成&認証
    foursquare = [[Foursquare alloc] init];
    foursquare.delegate = self;
    NSLog(@"%@", ([foursquare startAuthorization]? @"OK": @"NG"));
    
    // 変数初期化
	_longitude = 0.0;
	_latitude  = 0.0;
    nawabariSum = 0;
    
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
    
    [self performSelector:@selector(loadView) withObject:nil afterDelay:0.2];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
    // Do any additional setup after loading the view, typically from a nib.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_latitude
                                                            longitude:_longitude
                                                                 zoom:13];
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.delegate = self;
    mapView_.myLocationEnabled = YES;
    mapView_.settings.myLocationButton = YES;
    self.view = mapView_;
    
    // Creates a marker in the center of the map.
    GMSMarker* marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(_latitude, _longitude);
    //    marker.icon = [UIImage imageNamed:@"tokyo_tower64"];
    marker.title   = [NSString stringWithFormat:@"longitude%f",_longitude];
    marker.snippet = [NSString stringWithFormat:@"latitude%f" ,_latitude];
    marker.map = mapView_;
    
    [self drawNawabari];
}

// なわばり(markerのまわりの円)を描く
- (void)drawNawabari {
    CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(_latitude, _longitude);
    circ  = [GMSCircle circleWithPosition:circleCenter radius:100];
    circ.fillColor   = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.2];
    circ.strokeColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0];
    circ.map = mapView_;
    
    nawabariSum += pow(circ.radius/2, 2) * M_PI;
    NSLog([NSString stringWithFormat:@"%f", nawabariSum]);
}

#pragma mark -
#pragma mark FourSquareDelegate
- (void)requestDidSending {
    NSDictionary *response = [foursquare getResponse];
    NSLog(@"%@", [response description]);
}
/*
- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(id)marker {
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

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker {
    NSString* message = [NSString stringWithFormat:@"チェックインしますか?"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"title" message:message delegate:self
                                        cancelButtonTitle:@"キャンセル" otherButtonTitles:@"チェックイン", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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

- (void) mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    CGFloat zoom = mapView_.camera.zoom;
    CGFloat tmpRadius = 100 * 8192 / pow(2, zoom);
    if (tmpRadius > 100) {
        circ.radius = tmpRadius;
    } else {
        circ.radius = 100;
    }
}

@end
