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
    
/*
    [self loadView];
    NSArray *venues = @[@{
                            @"beenHere": @"2",
                            @"lat": @"35.65682575139073",
                            @"lng": @"139.694968886065",
                            @"name": @"ああああ",
                            @"venueId": @"4b4e9440f964a520f8f126e3"
                            },
                          @{
                              @"beenHere": @"1",
                              @"lat": @"35.65775608829579",
                              @"lng": @"139.700348675251",
                              @"name": @"いいいい",
                              @"venueId": @"4b5530abf964a52021de27e3"
                              }
                          ];
    NSDictionary *response = @{@"venues": venues};
    [self requestDidSending:response];
*/
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
    [self drawAreaInfoWindow];
    [self drawRankInfoWindow];
    [foursquareAPI requestSearchVenuesWithLatitude:latitude_ Longitude:longitude_];
}

- (void)getSearchVenues:(NSDictionary *)response {
    NSArray* surroundingVenues = (NSArray *)[response objectForKey:@"venues"];
    [self drawSurroundingNawabaris:surroundingVenues];
    NSLog(@"%@", [response description]);
    NSLog(@"%d", [(NSArray *)[response objectForKey:@"venues"] count]);
}

- (void)getCheckin:(NSDictionary *)response {
    NSString* message = [NSString stringWithFormat:@"チェックインしました!"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
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
        NSString *venueId = (NSString *)[venue objectForKey:@"venueId"];
        
        // Creates a marker in the center of the map.
        GMSMarker* marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(lat, lng);
        marker.icon = [UIImage imageNamed:@"blue_map_pin_17x32"];
        marker.title   = name;
        marker.snippet = venueId;
        marker.map = mapView_;
        
        CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(lat, lng);
        GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:(70 * beenHere)];
        circ.fillColor   = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.5];
        circ.strokeColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.8];
        circ.map = mapView_;
/*
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
*/
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
        NSString *venueId = (NSString *)[venue objectForKey:@"venueId"];
        
        // Creates a marker in the center of the map.
        GMSMarker* marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(lat, lng);
        marker.title   = name;
        marker.snippet = venueId;
        marker.map = mapView_;
        
        CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(lat, lng);
        GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:30];
        circ.fillColor   = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
        circ.strokeColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0];
        circ.map = mapView_;
    }
}

- (void)drawAreaInfoWindow {
    UIView *infoWindow = [[UIView alloc] initWithFrame:CGRectMake(6, 6, 180, 70)];
    infoWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(4, 4, 176, 18);
    titleLabel.font  = [UIFont boldSystemFontOfSize:16];
    titleLabel.text  = @"あなたの領土";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:titleLabel];
    
    UILabel *snippetLabel = [[UILabel alloc] init];
    snippetLabel.frame = CGRectMake(4, 20, 176, 46);
    snippetLabel.font  = [UIFont boldSystemFontOfSize:44];
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

    return infoWindow;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker {
    tappedVenue = [marker snippet];
    NSString* message = [NSString stringWithFormat:@"チェックインしますか?"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[marker title] message:message delegate:self
                                        cancelButtonTitle:@"キャンセル" otherButtonTitles:@"チェックイン", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            [foursquareAPI requestCheckin:tappedVenue];
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

- (void)drawRankInfoWindow {
    UIView *infoWindow = [[UIView alloc] initWithFrame:CGRectMake(192, 6, 122, 70)];
    infoWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(4, 4, 114, 18);
    titleLabel.font  = [UIFont boldSystemFontOfSize:16];
    titleLabel.text  = @"あなたの順位";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:titleLabel];
    
    UILabel *rankLabel = [[UILabel alloc] init];
    rankLabel.frame = CGRectMake(4, 24, 70, 46);
    rankLabel.font  = [UIFont boldSystemFontOfSize:32];
    NSDictionary *dict = [self getRankAndUsersNumById:1 andTerritory:nawabariAreaSum];
    NSString *rank     = [dict objectForKey:@"rank"];
    NSString *usersNum = [dict objectForKey:@"users_num"];
    rankLabel.text  = [NSString stringWithFormat:@"%@位", rank];
    rankLabel.textColor = [UIColor whiteColor];
    rankLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:rankLabel];
    
    UILabel *rankLabel2 = [[UILabel alloc] init];
    rankLabel2.frame = CGRectMake(76, 46, 44, 16);
    rankLabel2.font  = [UIFont boldSystemFontOfSize:14];
    rankLabel2.text  = [NSString stringWithFormat:@"/%@人", usersNum];
    rankLabel2.textColor = [UIColor whiteColor];
    rankLabel2.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:rankLabel2];
    
    [self.view addSubview:infoWindow];
}

- (NSDictionary *)getRankAndUsersNumById:(int)id andTerritory:(double)territory {
    NSString *urlStr = [NSString stringWithFormat:@"http://quiet-wave-3026.herokuapp.com/users/update/%d?territory=%f", id, territory];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSHTTPURLResponse *response;
    NSError *error;
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData
                                                     options:NSJSONReadingAllowFragments
                                                       error:&error];
    for (NSDictionary *dict in array) {
        return dict;
    }
}

@end
