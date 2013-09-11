//
//  Foursquare.m
//  NawabariWatch
//
//  Created by techcamp on 2013/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "FoursquareAPI.h"
#define kClientID       @"CEZDNWYSVK05PX2EHTOB1WJJ5PUEOF0GRUBTASMG0K2E1IGF"
#define kClientSecret   @"N1Y2QLO2JTCOILYFYRCTCHOWC3RMM5B0NHB13WMN0JVEDPFB"
#define kCallbackURL    @"nawabariwatch://foursquare"

@interface FoursquareAPI()
@property(nonatomic,readwrite,strong) BZFoursquare *foursquare;
@property(nonatomic,strong) BZFoursquareRequest *request;
@property(nonatomic,copy) NSDictionary *meta;
@property(nonatomic,copy) NSArray *notifications;
@property(nonatomic) int responseType;
@property(nonatomic) int offset;

-(BOOL)isAuthenticated;
-(BOOL)startAuthorization;
-(BOOL)handleOpenURL:(NSURL *)url;
-(void)prepareForRequestWithType:(int)type;
-(void)cancelRequest;
-(void)requestVenueHistory;
-(void)requestSearchVenuesWithLatitude:(double)lat Longitude:(double)lng;
-(void)requestCheckin:(NSString *)venueId;
@end

@implementation FoursquareAPI
@synthesize foursquare = foursquare_;
@synthesize request = request_;
@synthesize meta = meta_;
@synthesize notifications = notifications_;
@synthesize responseType = responseType_;
@synthesize offset = offset_;

- (id)init {
    self = [super init];
    if (self) {
        self.foursquare = [[BZFoursquare alloc] initWithClientID:kClientID clientSecret:kClientSecret callbackURL:kCallbackURL];
        foursquare_.version = @"20111119";
        foursquare_.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        foursquare_.sessionDelegate = self;
    }
    return self;
}

- (void)dealloc {
    foursquare_.sessionDelegate = nil;
    [self cancelRequest];
}

-(BOOL)isAuthenticated {
    return [foursquare_ isSessionValid];
}

-(BOOL)startAuthorization {
    return [foursquare_ startAuthorization];
}

-(BOOL)handleOpenURL:(NSURL *)url {
    return [foursquare_ handleOpenURL:url];
}

- (void)cancelRequest {
    if (request_) {
        request_.delegate = nil;
        [request_ cancel];
        self.request = nil;
        self.responseType = -1;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)prepareForRequestWithType:(int)type {
    [self cancelRequest];
    self.meta = nil;
    self.notifications = nil;
    response = [NSMutableDictionary dictionary];
    self.responseType = type;
}

//userのvenueHistoryを取得する
-(void) requestVenueHistory {
    [self prepareForRequestWithType: venueHistory];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: nil];
    self.request = [foursquare_ requestWithPath:@"users/self/venuehistory" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [request_ start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

//現在地を元に周辺のvenueを取得する
-(void) requestSearchVenuesWithLatitude:(double)lat Longitude:(double)lng {
    [self prepareForRequestWithType: searchVenues];
    NSString *ll = [NSString stringWithFormat:@"%f,%f", lat, lng];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"checkin", @"intent", @" ", @"query", @"15", @"limit", ll, @"ll", nil];
    self.request = [foursquare_ userlessRequestWithPath:@"venues/search" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [request_ start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void) requestCheckin:(NSString *)venueId {
    [self prepareForRequestWithType: checkin];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:venueId, @"venueId", @"public", @"broadcast", nil];
    self.request = [foursquare_ requestWithPath:@"checkins/add" HTTPMethod:@"POST" parameters:parameters delegate:self];
    [request_ start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

//userのプロファイルを取得
-(void) requestUserProfile {
    [self prepareForRequestWithType: userProfile];
    NSDictionary * parameters = [NSDictionary dictionaryWithObjectsAndKeys: nil];
    self.request = [foursquare_ requestWithPath:@"users/self" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [request_ start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

//最大１ヶ月分のチェックインのリストを取得する。
-(void) requestCheckinHistoryFirst {
    [self prepareForRequestWithType:checkinHistory];
    self.offset = 0;
    [self requestCheckinHistory];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void) requestCheckinHistory {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithFormat:@"%d", LIMIT], @"limit",
                                [NSString stringWithFormat:@"%d", self.offset], @"offset",
                                nil];
    self.request = [foursquare_ requestWithPath:@"users/self/checkins" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [request_ start];
    self.offset++;
}

//responseから、必要なvenue情報（@name、@venueid、@lat、@lng、@beenHere）を取り出す。
/*  venueHistoryの記述形式
        venues = (
            { beenHere = [回数], venue = [venueの情報] },
            { beenHere = [回数], venue = [venueの情報] },
            ...
        )
 
    searchVenuesの記述形式
        venues = ([venueの情報], [venueの情報], ...)
*/
-(NSDictionary *) convertResponse: (NSDictionary *)jsonObj {
    //venueのリスト
    id venues = [jsonObj objectForKey:@"venues"];
    NSMutableArray *useVenues = [NSMutableArray array];
    
    //venuesのリストの要素をarrayで取得
    NSMutableArray *items = [NSMutableArray array];
    
    switch (self.responseType) {
        case venueHistory:
            items = (NSMutableArray *)[((NSDictionary *)venues) objectForKey:@"items"];
            break;
        
        //searchVenuesのレスポンス記述形式をvenueHistoryにあわせる
        case searchVenues:
            items = [NSMutableArray array];
            for( id venue in (NSArray *) venues) {
                NSDictionary * item = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"", @"beenHere",
                                       (NSArray *)venue, @"venue",
                                       nil];
                [items insertObject:item atIndex: [items count]];
            }
            break;
        case checkinHistory:
            items = (NSMutableArray *)[jsonObj objectForKey:@"items"];
            break;
    }
    
    //レスポンスから、必要な情報だけ切り抜いてuseVenueに格納
    for (id item in items) {
        NSDictionary *venue = [item objectForKey:@"venue"];
        NSDictionary *location = (NSDictionary *)[venue objectForKey:@"location"];
        
        NSDictionary *useVenue =  [NSDictionary dictionaryWithObjectsAndKeys:
                                   (NSString *)[venue objectForKey:@"name"],        @"name",
                                   (NSString *)[venue objectForKey:@"id"],          @"venueId",
                                   (NSString *)[location objectForKey:@"lat"],      @"lat",
                                   (NSString *)[location objectForKey:@"lng"],      @"lng",
                                   (NSString *)[item objectForKey:@"beenHere"],    @"beenHere",
                                   nil];
        
        [useVenues addObject:useVenue];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", self.responseType ], @"responseType", useVenues, @"venues", nil];
}



#pragma mark -
#pragma mark BZFoursquareRequestDelegate

//requestのレスポンスが帰ってくる
- (void)requestDidFinishLoading:(BZFoursquareRequest *)request {
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.request = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    switch (self.responseType) {
        case venueHistory: {
            [_delegate getVenueHistory: [self convertResponse: request.response]];
            break;
        }
        case searchVenues: {
            [_delegate getSearchVenues: [self convertResponse: request.response]];
            break;
        }
        case userProfile: {
            break;
        }
        case checkin: {
            [_delegate getCheckin:request.response];
            break;
        }
        case checkinHistory: {
            NSDictionary *checkins = (NSDictionary *)[request.response objectForKey: @"checkins"];
            int count = (int)[checkins objectForKey:@"count"];
            NSDictionary *convertResponce = [self convertResponse:checkins];
            [response addEntriesFromDictionary:(NSMutableDictionary *)convertResponce];
            for(id tmp in (NSArray *)[convertResponce objectForKey:@"venues"]) {
                NSDictionary *venue = (NSDictionary *)tmp;
                NSString *key =[NSString stringWithFormat:@"%d", [response count]];
                NSLog(@"%@ %@", [venue description], key);
                
            }
            if(count != 100) {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                [_delegate getCheckinHistory:(NSDictionary *)response];
                return;
            }
            else {
                [self requestCheckinHistory];
                return;
            }
        }
    }
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[error userInfo] objectForKey:@"errorDetail"] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
    self.meta = request.meta;
    self.notifications = request.notifications;
//    self.response = request.response;
    self.request = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark BZFoursquareSessionDelegate

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare {
//    [_delegate didAuthorize];
    NSLog(@"a");
    [self requestCheckinHistoryFirst];
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorInfo);
}

@end
