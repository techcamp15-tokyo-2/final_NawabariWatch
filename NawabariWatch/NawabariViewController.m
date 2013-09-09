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
@synthesize foursquareAPI = foursquareAPI;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //foursquareの汎用クラスを作成&認証
    foursquareAPI = [[FoursquareAPI alloc] init];
    foursquareAPI.delegate = self;
    [foursquareAPI startAuthorization];
    
    // 変数初期化
	longitude_ = 0.0;
	latitude_  = 0.0;
    
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

#pragma mark -
#pragma mark FourSquareAPIDelegate
// 認証が終わったタイミングで呼ばれる
- (void)didAuthorize {
    [self loadView];
    
    [foursquareAPI requestVenueHistory];
}

- (void)getVenueHistory:(NSDictionary *)response {
    NSArray* venues = (NSArray *)[response objectForKey:@"venues"];
    [self drawNawabaris:venues];
    [foursquareAPI requestSearchVenuesWithLatitude:latitude_ Longitude:longitude_];
    [self drawInfoWindow];
}

- (void)getSearchVenues:(NSDictionary *)response {
    NSLog(@"%@", [response description]);
}

// google map 関連の処理
- (void)loadView {
    // Do any additional setup after loading the view, typically from a nib.
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude_
                                                            longitude:longitude_
                                                                 zoom:16];
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.delegate = self;
    mapView_.myLocationEnabled = YES;
    mapView_.settings.myLocationButton = YES;
    self.view = mapView_;
}

// なわばり(markerとそのまわりの円)を描く
- (void)drawNawabaris:(NSArray *)venues {
    nawabaris = [[NSMutableArray alloc] init];
    nawabariAreaSum = 0;
    
    for (id venue in venues) {
        CLLocationDegrees lat = [(NSString *)[venue objectForKey:@"lat"] doubleValue];
        CLLocationDegrees lng = [(NSString *)[venue objectForKey:@"lng"] doubleValue];
        NSString *name = (NSString *)[venue objectForKey:@"name"];
        int beenHere = [(NSString *)[venue objectForKey:@"beenHere"] intValue];
        
        // Creates a marker in the center of the map.
        GMSMarker* marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(lat, lng);
        //    marker.icon = [UIImage imageNamed:@"tokyo_tower64"];
        marker.title   = name;
        marker.map = mapView_;
        
        CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(lat, lng);
        GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:(100 * beenHere)];
        circ.fillColor   = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.5];
        circ.strokeColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0];
//        circ.map = mapView_;

        GMSMutablePath *rect = [GMSMutablePath path];
        double halfWidth = 0.001;
        [rect addCoordinate:CLLocationCoordinate2DMake(lat - halfWidth, lng - halfWidth)];
        [rect addCoordinate:CLLocationCoordinate2DMake(lat + halfWidth, lng - halfWidth)];
        [rect addCoordinate:CLLocationCoordinate2DMake(lat + halfWidth, lng + halfWidth)];
        [rect addCoordinate:CLLocationCoordinate2DMake(lat - halfWidth, lng + halfWidth)];
        [rect addCoordinate:CLLocationCoordinate2DMake(lat - halfWidth, lng - halfWidth)];
        
        GMSPolygon *polygon = [GMSPolygon polygonWithPath:rect];
        polygon.fillColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.2];
        polygon.strokeColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.8];
        polygon.strokeWidth = 2;
        polygon.map = mapView_;
        
        for (int i = -4; i < 5; i++) {
            GMSMutablePath *path = [GMSMutablePath path];
            double width = halfWidth * i / 5;
            [path addCoordinate:CLLocationCoordinate2DMake(lat - width, lng - halfWidth)];
            [path addCoordinate:CLLocationCoordinate2DMake(lat - width, lng + halfWidth)];
            GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
            polyline.strokeColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.8];
            polyline.strokeWidth = 10;
            polyline.map = mapView_;
        }

        NSDictionary* nawabari = @{
            @"marker": marker,
            @"circ": circ,
            @"defaultRadius": [NSString stringWithFormat:@"%f", circ.radius]
        };
        [nawabaris addObject:nawabari];
        
        nawabariAreaSum += pow(circ.radius/2, 2) * M_PI;
    }
}

- (void)drawSurroundingNawabaris:(NSArray *)venues {
    for (id venue in venues) {
        CLLocationDegrees lat = [(NSString *)[venue objectForKey:@"lat"] doubleValue];
        CLLocationDegrees lng = [(NSString *)[venue objectForKey:@"lng"] doubleValue];
        NSString *name = (NSString *)[venue objectForKey:@"name"];
        
        // Creates a marker in the center of the map.
        GMSMarker* marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(lat, lng);
        marker.title   = name;
        marker.map = mapView_;
        
        
        CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(lat, lng);
        GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:100];
        circ.fillColor   = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
        circ.strokeColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0];
        circ.map = mapView_;
    }
}

- (void)drawAreaInfoWindow {
    UIView *infoWindow = [[UIView alloc] initWithFrame:CGRectMake(4, 4, 90, 40)];
    infoWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(4, 2, 86, 14);
    titleLabel.font  = [UIFont boldSystemFontOfSize:12];
    titleLabel.text  = @"あなたの領土";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:titleLabel];
    
    UILabel *snippetLabel = [[UILabel alloc] init];
    snippetLabel.frame = CGRectMake(4, 16, 86, 22);
    snippetLabel.font  = [UIFont boldSystemFontOfSize:20];
    snippetLabel.text  = [NSString stringWithFormat:@"%.0f坪", nawabariAreaSum/3.30578512];
    snippetLabel.textColor = [UIColor whiteColor];
    snippetLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:snippetLabel];
    
    [self.view addSubview:infoWindow];
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(id)marker {
    // infoWindowを作る
    UIView *infoWindow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 40)];
    infoWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(10, 10, 160, 20);
    titleLabel.font  = [UIFont boldSystemFontOfSize:18];
    titleLabel.text  = [marker title];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
    [infoWindow addSubview:titleLabel];
 
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    btn.frame = CGRectMake(100, 0, 40, 40);
    [infoWindow addSubview:btn];

    return infoWindow;
}

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

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    CGFloat zoom = mapView_.camera.zoom;
    CGFloat minRadius = 100 * 8192 / pow(2, zoom);
    for (id nawabari in nawabaris) {
        GMSCircle* circ = (GMSCircle*)[(NSDictionary*)nawabari objectForKey:@"circ"];
        CGFloat defaultRadius = [[(NSDictionary*)nawabari objectForKey:@"defaultRadius"] floatValue];
        
        if (minRadius >= defaultRadius) {
            circ.radius = minRadius;
        } else {
            circ.radius = defaultRadius;
        }
    }
}

- (void)getRank:(int)id {
    NSString *urlStr = [@"http://quiet-wave-3026.herokuapp.com/users/rank/" stringByAppendingFormat:@"%i", id];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSHTTPURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
