//
//  NawabariViewController.m
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/04.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "NawabariViewController.h"
#import "NawabariViewController+Location.m"

#define kUnitRadius 40

@implementation NawabariViewController 
@synthesize foursquareAPI = foursquareAPI;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //foursquareの汎用クラスを作成&認証
    foursquareAPI = [[FoursquareAPI alloc] init];
    if(![foursquareAPI isAuthenticated]) {
        
        NSString* message = [NSString stringWithFormat:@"foursquareの認証がされていません。認証してください！"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.tag = startAuthorization;
        [alert show];
    }
    
    // 変数初期化
	longitude_ = 0.0;
	latitude_  = 0.0;
    textColorBlack = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.8];
    backgroundColorWhite = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    backgroundColorBlack = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
    isDisplayMarker = TRUE;
    
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
    [foursquareAPI requestCheckinHistoryFirst];
}

// userのvenue historyを取得した後に呼ばれる
- (void)getVenueHistory:(NSDictionary *)response {
    NSArray* venues = (NSArray *)[response objectForKey:@"venues"];
    [self drawNawabaris:venues];
    [self drawAreaInfoWindow];
    [self drawSurroundingNawabarisButton];
    [foursquareAPI requestUserProfile];
}

// userのprofileを取得した後に呼ばれる
- (void)getUserProfile:(NSDictionary *)response {
    NSString *userId = [response objectForKey:@"userId"];
    [self drawRankInfoWindow:userId];
}

- (void)requestSearchNeighborVenues {
    [foursquareAPI requestSearchVenuesWithLatitude:latitude_ Longitude:longitude_];
    [mapView_ animateToCameraPosition:[GMSCameraPosition
                                       cameraWithLatitude:latitude_
                                       longitude:longitude_
                                       zoom:18]];
}

// 近郊のvenueを取得した後に呼ばれる
- (void)getSearchVenues:(NSDictionary *)response {
    for (NSMutableDictionary *nawabari in surroundingNawabaris) {
        GMSMarker* marker = [nawabari objectForKey:@"marker"];
        marker.map = nil;
        GMSCircle *circ = [nawabari objectForKey:@"circ"];
        circ.map = nil;
    }

    NSArray* surroundingVenues = (NSArray *)[response objectForKey:@"venues"];
    [self drawSurroundingNawabaris:surroundingVenues];
}

// チェックイン後に呼ばれる
- (void)getCheckin:(NSDictionary *)response {    
    NSString* message = [NSString stringWithFormat:@"チェックインしました!"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"didCheckin" message:message delegate:self
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alert.tag = finishCheckin;
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

// markerがtapされた時、info windowを表示
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

// info windowがtapされた時、alertを表示
- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker {
    tappedVenueId = [marker snippet];
    NSString* message = [NSString stringWithFormat:@"チェックインしますか?"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[marker title]
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"キャンセル"
                                          otherButtonTitles:@"チェックイン", nil];
    alert.tag = requestCheckin;
    [alert show];
}

// cameraの移動やzoom時に、なわばりの半径を再描画
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
//        marker.icon = [UIImage imageNamed:@"blue_map_pin_17x32"];
        marker.icon = [UIImage imageNamed:@"icon_6m_48"];

        marker.title   = name;
        marker.snippet = venueId;
        if (isDisplayMarker) {
            marker.map = mapView_;
        }

        CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(lat, lng);
        GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:(kUnitRadius * sqrt(beenHere))];
        circ.fillColor   = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.4];
        circ.strokeColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.8];
//        circ.fillColor   = [UIColor colorWithRed:0 green:0.9 blue:0.2 alpha:0.2];
//        circ.strokeColor = [UIColor colorWithRed:0 green:0.9 blue:0.2 alpha:0.8];
        circ.map = mapView_;

/*
        GMSMutablePath *rect = [GMSMutablePath path];
        double halfWidth = 0.0002;
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
        NSMutableDictionary* nawabari = [@{
            @"marker": marker,
            @"circ": circ,
            @"defaultRadius": [NSNumber numberWithFloat:circ.radius]
        } mutableCopy];
        [nawabaris addObject:nawabari];
        
        nawabariAreaSum += pow(circ.radius, 2) * M_PI;
    }
}

// 近郊の自分のでないなわばりを描画
- (void)drawSurroundingNawabaris:(NSArray *)venues {
    surroundingNawabaris = [[NSMutableArray alloc] init];
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
        if (isDisplayMarker) {
            marker.map = mapView_;
        }
//        marker.icon = [UIImage imageNamed:@"cat1"];
        
        CLLocationCoordinate2D circleCenter = CLLocationCoordinate2DMake(lat, lng);
        GMSCircle* circ  = [GMSCircle circleWithPosition:circleCenter radius:kUnitRadius];
        circ.fillColor   = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
        circ.strokeColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.4];
        circ.map = mapView_;
        
        NSMutableDictionary* nawabari = [@{
                                         @"marker": marker,
                                         @"circ": circ,
                                         @"defaultRadius": [NSNumber numberWithFloat:circ.radius]
                                         } mutableCopy];
        [surroundingNawabaris addObject:nawabari];
    }
}

// 領土情報windowを描画
- (void)drawAreaInfoWindow {
    UIButton *infoWindow = [UIButton buttonWithType:UIButtonTypeCustom];
    infoWindow.frame = CGRectMake(4, 4, 180, 70);
    [infoWindow setBackgroundImage:[self createBackgroundImage:backgroundColorWhite withSize:CGSizeMake(122, 70)]
                          forState:UIControlStateNormal];
    [infoWindow setBackgroundImage:[self createBackgroundImage:backgroundColorBlack withSize:CGSizeMake(122, 70)]
                          forState:(UIControlStateSelected | UIControlStateHighlighted)];
    [infoWindow.layer setCornerRadius:10.0];
    [infoWindow.layer setBorderColor:[UIColor grayColor].CGColor];
    [infoWindow.layer setBorderWidth:1.0];
    [infoWindow setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [infoWindow addTarget:self action:@selector(changeDisplayNawabaris) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(6, 6, 176, 18);
    titleLabel.font  = [UIFont boldSystemFontOfSize:16];
    titleLabel.text  = @"あなたの領土";
    titleLabel.textColor = textColorBlack;
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:titleLabel];
    
    areaLabel = [[UILabel alloc] init];
    areaLabel.frame = CGRectMake(4, 24, 176, 40);
    areaLabel.font  = [UIFont boldSystemFontOfSize:38];
    areaLabel.text  = [self getAreaLabelText];
    areaLabel.textColor = textColorBlack;
    areaLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:areaLabel];
    
    [self.view addSubview:infoWindow];
}

// 順位情報windowを描画
- (void)drawRankInfoWindow:(NSString *)userId {
    UIButton *infoWindow = [UIButton buttonWithType:UIButtonTypeCustom];
    infoWindow.frame = CGRectMake(192, 4, 122, 70);
    [infoWindow setBackgroundImage:[self createBackgroundImage:backgroundColorWhite withSize:CGSizeMake(122, 70)]
                            forState:UIControlStateNormal];
    [infoWindow setBackgroundImage:[self createBackgroundImage:backgroundColorBlack withSize:CGSizeMake(122, 70)]
                            forState:(UIControlStateSelected | UIControlStateHighlighted)];
    [infoWindow.layer setCornerRadius:10.0];
    [infoWindow.layer setBorderColor:[UIColor grayColor].CGColor];
    [infoWindow.layer setBorderWidth:1.0];
    [infoWindow setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [infoWindow addTarget:self action:@selector(transPageToRankView) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(6, 6, 114, 16);
    titleLabel.font  = [UIFont boldSystemFontOfSize:14];
    titleLabel.text  = @"全国ランキング";
    titleLabel.textColor = textColorBlack;
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:titleLabel];
    
    UILabel *rankLabel = [[UILabel alloc] init];
    rankLabel.frame = CGRectMake(6, 24, 70, 40);
    rankLabel.font  = [UIFont boldSystemFontOfSize:38];
    
    NSDictionary *dict = [self getRankAndUsersNumById:userId
                                         andTerritory:nawabariAreaSum];
    NSString *rank     = [dict objectForKey:@"rank"];
    NSString *usersNum = [dict objectForKey:@"users_num"];
    rankLabel.text  = [NSString stringWithFormat:@"%@位", rank];
    rankLabel.textColor = textColorBlack;
    rankLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:rankLabel];
    
    UILabel *rankLabel2 = [[UILabel alloc] init];
    rankLabel2.frame = CGRectMake(78, 46, 44, 16);
    rankLabel2.font  = [UIFont boldSystemFontOfSize:14];
    rankLabel2.text  = [NSString stringWithFormat:@"/%@人", usersNum];
    rankLabel2.textColor = textColorBlack;
    rankLabel2.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [infoWindow addSubview:rankLabel2];
    
    [self.view addSubview:infoWindow];
}

// venueを探すボタンを描画
- (void)drawSurroundingNawabarisButton {
    /*
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"venueを探す" forState:UIControlStateNormal];

    [[btn layer] setCornerRadius:3.0f];
    [[btn layer] setMasksToBounds:YES];
    [[btn layer] setBorderWidth:0.6f];
    [[btn layer] setBackgroundColor:
     [backgroundColorWhite CGColor]];

    [btn setTitleColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] forState:UIControlStateNormal];
    
    [btn addTarget:self action:@selector(requestSearchNeighborVenues) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundImage:[self createBackgroundImage:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] withSize:CGSizeMake(120, 40)]
                           forState:(UIControlStateSelected | UIControlStateHighlighted)];
    btn.showsTouchWhenHighlighted = YES;
    
    btn.frame = CGRectMake(5, self.view.frame.size.height - 40 - 6, 120, 40);
    [self.view addSubview:btn];
    */

    searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = CGRectMake(5, self.view.frame.size.height - 40 - 6, 120, 40);
    [searchButton setTitle:@"venueを探す" forState:UIControlStateNormal];
    [searchButton setBackgroundImage:[self createBackgroundImage:backgroundColorWhite withSize:CGSizeMake(120, 40)]
                         forState:UIControlStateNormal];
    [searchButton setBackgroundImage:[self createBackgroundImage:backgroundColorBlack withSize:CGSizeMake(120, 40)]
                   forState:(UIControlStateSelected | UIControlStateHighlighted)];
    [searchButton.layer setCornerRadius:10.0];
    [searchButton.layer setBorderColor:[UIColor grayColor].CGColor];
    [searchButton.layer setBorderWidth:1.0];
    [searchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    [searchButton addTarget:self action:@selector(requestSearchNeighborVenues) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
}

/*
// ランキングを見るボタンを描画
- (void)drawRankViewButton {
    searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = CGRectMake(192, 80, 122, 32);
    [searchButton setTitle:@"ランキング" forState:UIControlStateNormal];
    [searchButton setBackgroundImage:[self createBackgroundImage:backgroundColorWhite withSize:CGSizeMake(120, 40)]
                            forState:UIControlStateNormal];
    [searchButton setBackgroundImage:[self createBackgroundImage:backgroundColorBlack withSize:CGSizeMake(120, 40)]
                            forState:(UIControlStateSelected | UIControlStateHighlighted)];
    [searchButton.layer setCornerRadius:10.0];
    [searchButton.layer setBorderColor:[UIColor grayColor].CGColor];
    [searchButton.layer setBorderWidth:1.0];
    [searchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [searchButton addTarget:self action:@selector(transPageToRankView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
}
*/

// UIColorからUIImageを生成
- (UIImage *)createBackgroundImage:(UIColor *)color withSize:(CGSize)size {
    UIImage *screenImage;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.layer.cornerRadius = 10;
    view.clipsToBounds = true;
    view.backgroundColor = color;
    UIGraphicsBeginImageContext(size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    screenImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenImage;
}

// WebAPIをたたいてユーザーの順位と全ユーザー数を取得
- (NSDictionary *)getRankAndUsersNumById:(NSString *)userId andTerritory:(double)territory {
    NSString *urlStr = [NSString stringWithFormat:@"http://quiet-wave-3026.herokuapp.com/users/update/%@?territory=%f", userId, territory];
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
    
    return [[NSDictionary alloc] init];
}

// 順位windowに表示するStringを生成
- (NSString *) getAreaLabelText{
    return [NSString stringWithFormat:@"%.0f坪", nawabariAreaSum/3.30578512];
}

/*
// iPhoneを傾けた時に呼ばれるメソッド
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)FromInterfaceOrientation {
    searchButton.frame = CGRectMake(5, self.view.frame.size.height - 40 - 6, 120, 40);
    if(FromInterfaceOrientation == UIInterfaceOrientationPortrait){
        // 横向き
    } else {
        // 縦向き
    }
}
*/

// ランキングページへ遷移
- (void)transPageToRankView {
    RankViewController *next = [[RankViewController alloc] init];
    next.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:next animated:YES completion:^ {
        // 完了時の処理をここに書きます
    }];
}

// なわばりの表示・非表示を切り替え
- (void)changeDisplayNawabaris {
    isDisplayMarker = !isDisplayMarker;
    for (NSMutableDictionary *nawabari in nawabaris) {
        GMSMarker* marker = [nawabari objectForKey:@"marker"];
        if (isDisplayMarker) {
            marker.map = mapView_;
        } else {
            marker.map = nil;
        }
    }
    
    for (NSMutableDictionary *nawabari in surroundingNawabaris) {
        GMSMarker* marker = [nawabari objectForKey:@"marker"];
        GMSCircle* circ   = [nawabari objectForKey:@"circ"];
        if (isDisplayMarker) {
            marker.map = mapView_;
            circ.map   = mapView_;
        } else {
            marker.map = nil;
            circ.map   = nil;
        }
    }
}

// チェックイン後、なわばりの半径を変更
- (void)changeNawabariRadiusAfterCheckin {
    for (NSMutableDictionary *nawabari in nawabaris) {
        GMSMarker* marker = [nawabari objectForKey:@"marker"];
        if (marker.snippet == tappedVenueId) {
            CGFloat radius = [[nawabari objectForKey:@"defaultRadius"] floatValue];
            GMSCircle *circ = [nawabari objectForKey:@"circ"];
            
            nawabariAreaSum -= pow(circ.radius, 2) * M_PI;
            circ.radius = kUnitRadius * sqrt( pow(radius/kUnitRadius, 2) + 1);
            nawabariAreaSum += pow(circ.radius, 2) * M_PI;
            
            areaLabel.text = [self getAreaLabelText];
            [nawabari setObject:[NSNumber numberWithFloat:circ.radius] forKey:@"defaultRadius"];
            
            break;
        }
    }
    
    for (NSMutableDictionary *nawabari in surroundingNawabaris) {
        GMSMarker* marker = [nawabari objectForKey:@"marker"];
        if (marker.snippet == tappedVenueId) {
            marker.icon = [UIImage imageNamed:@"blue_map_pin_17x32"];
            GMSCircle *circ = [nawabari objectForKey:@"circ"];
            
            circ.fillColor   = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.4];
            circ.strokeColor = [UIColor colorWithRed:0 green:0.5804 blue:0.7843 alpha:0.8];
            nawabariAreaSum += pow(circ.radius, 2) * M_PI;
            
            areaLabel.text = [self getAreaLabelText];
            [nawabari setObject:[NSNumber numberWithFloat:circ.radius] forKey:@"defaultRadius"];
            
            break;
        }
    }
}

// alertのボタンを押したときに呼ばれるメソッド
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case startAuthorization:
            foursquareAPI.delegate = self;
            [foursquareAPI startAuthorization];
            break;
        
        case requestCheckin:
            switch (buttonIndex) {
                case 0:
                    break;
                case 1:
                    [foursquareAPI requestCheckin:tappedVenueId];
                    break;
                default:
                    break;
            }
            break;
        
        case finishCheckin:
            [self changeNawabariRadiusAfterCheckin];
            break;
    }
}

@end
