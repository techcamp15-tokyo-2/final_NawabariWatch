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
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 変数初期化
	longitude_ = 0.0;
	latitude_  = 0.0;
    textColorBlack = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.8];
    backgroundColorWhite = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    backgroundColorBlack = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
    isDisplayMarker = TRUE;
    isFirst = TRUE;
    rankDisplayButtonArray  =  [[NSMutableArray alloc] init];
    
    
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
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
//    [userDefault removeObjectForKey:@"access_token"];
    
    //foursquareの汎用クラスを作成&認証
    foursquareAPI = [[FoursquareAPI alloc] init];
    foursquareAPI.delegate = self;
    if(![foursquareAPI isAuthenticated]) {
        
        NSString* message = [NSString stringWithFormat:@"foursquareの認証が必要です。\n認証をお願いします。"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.tag = startAuthorization;
        [alert show];
    } else {
        [self loadView];
        [foursquareAPI requestCheckinHistoryFirst];
    }
}

- (void)didReceiveMemoryWarning {
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
    NSString *userId   = [response objectForKey:@"userId"];
    NSString *userName = [response objectForKey:@"firstName"];
    [self drawRankInfoWindowById:userId Name:userName];
}

// 近郊のvenueを探す
- (void)requestSearchNeighborVenues {
    [foursquareAPI requestSearchVenuesWithLatitude:latitude_ Longitude:longitude_];
    [mapView_ animateToCameraPosition:[GMSCameraPosition
                                       cameraWithLatitude:latitude_
                                       longitude:longitude_
                                       zoom:17]];
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
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self
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
    UIView *infoWindow = (UIView *)[self makeCustomButtonWithFrame:CGRectMake(0, 0, 180, 40)];
    
    UILabel *titleLabel = [self makeCustomLabelWithFrame:CGRectMake(10, 10, 160, 20)];
    titleLabel.font  = [UIFont boldSystemFontOfSize:18];
    titleLabel.text  = [marker title];
    [infoWindow addSubview:titleLabel];
    
    return infoWindow;
}

// info windowがtapされた時、alertを表示
- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker {
    tappedVenueId = [marker snippet];
    NSString* message = [NSString stringWithFormat:@"チェックインして領土を\n広げますか？"];
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
    nawabariVenueIds = [[NSMutableSet alloc] init];
    for (id venue in venues) {
        CLLocationDegrees lat = [(NSString *)[venue objectForKey:@"lat"] doubleValue];
        CLLocationDegrees lng = [(NSString *)[venue objectForKey:@"lng"] doubleValue];
        NSString *name = (NSString *)[venue objectForKey:@"name"];
        int beenHere = [(NSString *)[venue objectForKey:@"beenHere"] intValue];
        NSString *venueId = (NSString *)[venue objectForKey:@"venueId"];
        
        [nawabariVenueIds addObject:venueId];
        
        // Creates a marker in the center of the map.
        GMSMarker* marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(lat, lng);
        marker.icon = [UIImage imageNamed:@"blue_map_pin_17x32"];
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
    for (NSDictionary* venue in venues) {
        CLLocationDegrees lat = [(NSString *)[venue objectForKey:@"lat"] doubleValue];
        CLLocationDegrees lng = [(NSString *)[venue objectForKey:@"lng"] doubleValue];
        NSString *name = (NSString *)[venue objectForKey:@"name"];
        NSString *venueId = (NSString *)[venue objectForKey:@"venueId"];
        
        if ([nawabariVenueIds containsObject:venueId]) {
            continue;
        }
        
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
    areaInfoWindowButton = [self makeCustomButtonWithFrame:CGRectMake(4, 4, 180, 70)];
    [areaInfoWindowButton addTarget:self action:@selector(changeDisplayNawabaris) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *titleLabel = [self makeCustomLabelWithFrame:CGRectMake(6, 6, 176, 18)];
    titleLabel.font  = [UIFont boldSystemFontOfSize:16];
    titleLabel.text  = @"あなたの領土";
    [areaInfoWindowButton addSubview:titleLabel];
    
    areaLabel = [self makeCustomLabelWithFrame:CGRectMake(4, 24, 176, 40)];
    areaLabel.font  = [UIFont boldSystemFontOfSize:38];
    areaLabel.text  = [self getAreaLabelText];
    [areaInfoWindowButton addSubview:areaLabel];
    
    [self.view addSubview:areaInfoWindowButton];
}

// 順位情報windowを描画
- (void)drawRankInfoWindowById:(NSString *)userId Name:(NSString *)userName {
    NSDictionary *rankAndUsersNum = [self getRankAndUsersNumById:userId
                                                            Name:userName
                                                       Territory:nawabariAreaSum];
    NSString *rank     = [rankAndUsersNum objectForKey:@"rank"];
    NSString *usersNum = [rankAndUsersNum objectForKey:@"users_num"];
    
    rankInfoWindowButton = [self makeCustomButtonWithFrame:CGRectMake(190, 4, 125, 70)];
    [rankInfoWindowButton addTarget:self action:@selector(drawRankView) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *titleLabel = [self makeCustomLabelWithFrame:CGRectMake(6, 6, 114, 18)];
    titleLabel.font  = [UIFont boldSystemFontOfSize:16];
    titleLabel.text  = @"全国ランキング";
    [rankInfoWindowButton addSubview:titleLabel];
    
    UILabel *rankLabel = [self makeCustomLabelWithFrame:CGRectMake(6, 24, 70, 40)];
    rankLabel.font  = [UIFont boldSystemFontOfSize:38];
    rankLabel.text  = [NSString stringWithFormat:@"%@位", rank];
    [rankInfoWindowButton addSubview:rankLabel];
    
    UILabel *rankLabel2 = [self makeCustomLabelWithFrame:CGRectMake(78, 46, 44, 16)];
    rankLabel2.font  = [UIFont boldSystemFontOfSize:14];
    rankLabel2.text  = [NSString stringWithFormat:@"/%@人", usersNum];
    [rankInfoWindowButton addSubview:rankLabel2];
    
    [self.view addSubview:rankInfoWindowButton];
}

// venueを探すボタンを描画
- (void)drawSurroundingNawabarisButton {
    searchButton = [self makeCustomButtonWithFrame:CGRectMake(5, self.view.frame.size.height - 40 - 6, 130, 40)];
    [searchButton setTitle:@"領土を開拓" forState:UIControlStateNormal];

    [searchButton addTarget:self action:@selector(requestSearchNeighborVenues) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
}

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
- (NSDictionary *)getRankAndUsersNumById:(NSString *)userId Name:(NSString *)userName Territory:(double)territory {
    NSString *urlStr = [NSString stringWithFormat:@"http://quiet-wave-3026.herokuapp.com/users/update/%@/%@/%f", userId, userName, territory];
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

// 全国ランキングページを描画
- (void)drawRankView {
    areaInfoWindowButton.enabled = NO;
    [rankInfoWindowButton removeFromSuperview];
    [searchButton removeFromSuperview];
    
    // 白文字の色を指定
    UIColor *textColorWhite = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.92];
    
    // 全国ランキングを表示するview
    rankView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    rankView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    
    UIView *rankSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 90, self.view.frame.size.width - 90, self.view.frame.size.height)];
    [rankView addSubview:rankSubView];    
    [self.view addSubview:rankView];
    
    // ランキングタイトル
    UILabel *titleLabel = [self makeCustomLabelWithFrame:CGRectMake((self.view.frame.size.width - 280)/2, 0, 280, 42)];
    titleLabel.font  = [UIFont boldSystemFontOfSize:40];
    titleLabel.text  = @"全国ランキング";
    titleLabel.textColor = textColorWhite;
    [rankSubView addSubview:titleLabel];
    
    NSArray *rankingTopFive = [self getRankingTopFive];
    // 順位ラベル
    for (int i = 0; i < 5; i++) {
        NSDictionary *ranker = [rankingTopFive objectAtIndex:i];
        NSString *name  = [ranker objectForKey:@"name"];
        float area = [[ranker objectForKey:@"area"] floatValue];
        
        UIButton *tmpButton = [[UIButton alloc] init];
        tmpButton = [self makeCustomButtonWithFrame:CGRectMake(25,
                                                               145 + 32 * i,
                                                               280,
                                                               27)];
        
        UILabel *rankLabel = [self makeCustomLabelWithFrame:CGRectMake(0,
                                                                       0,
                                                                       52,
                                                                       27)];
        rankLabel.font  = [UIFont boldSystemFontOfSize:25];
        rankLabel.text  = [NSString stringWithFormat:@"%d位:", i + 1];
        [tmpButton addSubview:rankLabel];
        
        UILabel *nameLabel = [self makeCustomLabelWithFrame:CGRectMake(55,
                                                                       0,
                                                                       95,
                                                                       27)];
        nameLabel.font  = [UIFont boldSystemFontOfSize:25];
        nameLabel.text  = [NSString stringWithFormat:@"%@", name];
        [tmpButton addSubview:nameLabel];
        
        UILabel *tmpAreaLabel = [self makeCustomLabelWithFrame:CGRectMake(153,
                                                                       0,
                                                                       117,
                                                                       27)];
        tmpAreaLabel.font  = [UIFont boldSystemFontOfSize:25];
        tmpAreaLabel.text  = [NSString stringWithFormat:@"%.2f万坪", area / 10000 / 3.30578512];
        [tmpButton addSubview:tmpAreaLabel];
        
        [rankDisplayButtonArray addObject:tmpButton];
        [self.view addSubview:tmpButton];
    }
    
    UILabel *messageLabel = [self makeCustomLabelWithFrame:CGRectMake(0, 0, 0, 0)];
    messageLabel.font  = [UIFont boldSystemFontOfSize:32];
    messageLabel.text  = @"1位まであと少し。";
    [messageLabel sizeToFit];
    messageLabel.frame = CGRectMake((self.view.frame.size.width - messageLabel.frame.size.width)/2,
                                    235,
                                    messageLabel.frame.size.width,
                                    messageLabel.frame.size.height);
    messageLabel.textColor = textColorWhite;
    [rankSubView addSubview:messageLabel];

    [self drawBackButton];
}

// 全国ランキングtop5を取得する
- (NSArray *)getRankingTopFive {
    NSString *urlStr = [NSString stringWithFormat:@"http://quiet-wave-3026.herokuapp.com/users/ranking/5"];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSHTTPURLResponse *response;
    NSError *error;
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSArray *rankingTopFive = [NSJSONSerialization JSONObjectWithData:jsonData
                                                     options:NSJSONReadingAllowFragments
                                                       error:&error];
    return rankingTopFive;
}

// Mapへ戻るボタンを描画
- (void)drawBackButton {
    backToMapButton = [self makeCustomButtonWithFrame:CGRectMake(190, 4, 125, 70)];
    [backToMapButton addTarget:self action:@selector(backButtonDidPush) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *titleLabel = [self makeCustomLabelWithFrame:CGRectMake(12.5, 1, 116, 69)];
    titleLabel.font  = [UIFont boldSystemFontOfSize:18];
    titleLabel.text  = @"MAPに戻る";
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [backToMapButton addSubview:titleLabel];
    
    [self.view addSubview:backToMapButton];
}

// Mapへ戻るボタンが押された時の処理
- (void)backButtonDidPush {
    [rankView removeFromSuperview];
    [backToMapButton removeFromSuperview];
    for (UIButton *tmpButton in rankDisplayButtonArray) {
        [tmpButton removeFromSuperview];
    }
    
    areaInfoWindowButton.enabled = YES;
    [self.view addSubview:areaInfoWindowButton];
    [self.view addSubview:rankInfoWindowButton];
    [self.view addSubview:searchButton];
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

// チェックイン後、なわばりの半径や色を変更
- (void)changeNawabariRadiusAfterCheckin {
    [NSThread sleepForTimeInterval:0.6];
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
            
            NSMutableDictionary *newNawabari = [NSMutableDictionary dictionaryWithDictionary:nawabari];            
            [nawabaris addObject:newNawabari];
            [surroundingNawabaris removeObject:nawabari];
            
            break;
        }
    }
}

// customButtonを作成
- (UIButton *)makeCustomButtonWithFrame:(CGRect)frame {
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.frame = frame;
    [customButton setBackgroundImage:[self createBackgroundImage:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.92] withSize:frame.size]
                            forState:UIControlStateNormal];
    [customButton setBackgroundImage:[self createBackgroundImage:backgroundColorBlack withSize:frame.size]
                            forState:(UIControlStateSelected | UIControlStateHighlighted)];
    [customButton.layer setCornerRadius:10.0];
    [customButton.layer setBorderColor:[UIColor grayColor].CGColor];
    [customButton.layer setBorderWidth:1.0];
    [customButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    return customButton;
}

// customLabelを作成
- (UILabel *)makeCustomLabelWithFrame:(CGRect)frame {
    UILabel *customLabel = [[UILabel alloc] init];
    customLabel.frame = frame;
    customLabel.font  = [UIFont boldSystemFontOfSize:16];
    customLabel.text  = @"デフォルトです";
    customLabel.textColor = textColorBlack;
    customLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    return customLabel;
}

// alertのボタンを押したときに呼ばれるメソッド
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case startAuthorization:
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
