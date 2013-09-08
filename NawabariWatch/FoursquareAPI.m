//
//  Foursquare.m
//  NawabariWatch
//
//  Created by techcamp on 2013/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "FoursquareAPI.h"
#define kClientID       @"CEZDNWYSVK05PX2EHTOB1WJJ5PUEOF0GRUBTASMG0K2E1IGF"
#define kCallbackURL    @"nawabariwatch://foursquare"

@interface FoursquareAPI()
@property(nonatomic,readwrite,strong) BZFoursquare *foursquare;
@property(nonatomic,strong) BZFoursquareRequest *request;
@property(nonatomic,copy) NSDictionary *meta;
@property(nonatomic,copy) NSArray *notifications;
@property(nonatomic,copy) NSDictionary *response;
@property(nonatomic) int responseType;
-(BOOL)isAuthenticated;
-(BOOL)startAuthorization;
-(BOOL)handleOpenURL:(NSURL *)url;
-(void)prepareForRequestWithType:(int)type;
-(void)cancelRequest;
-(void)requestVenueHistory;
-(void)requestSearchVenuesWithLatitude:(double)lat Longitude:(double)lng;
@end

@implementation FoursquareAPI
@synthesize foursquare = foursquare_;
@synthesize request = request_;
@synthesize meta = meta_;
@synthesize notifications = notifications_;
@synthesize response = response_;

- (id)init {
    self = [super init];
    if (self) {
        self.foursquare = [[BZFoursquare alloc] initWithClientID:kClientID callbackURL:kCallbackURL];
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
    self.response = nil;
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
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:ll, @"ll", nil];
    self.request = [foursquare_ requestWithPath:@"venues/search" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [request_ start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

//userのプロファイルを取得
-(void) requestUserProfile {
//    [self prepareForRequest: ];
    NSDictionary * parameters = [NSDictionary dictionaryWithObjectsAndKeys: nil];
    self.request = [foursquare_ requestWithPath:@"users/self" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [request_ start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

//responseから、必要なvenue情報（@name、@venueid、@lat、@lng、@beenHere）を取り出す。
-(NSDictionary *) convertResponse: (NSDictionary *)response {
    //venueのリスト
    NSDictionary *venues = (NSDictionary *)[response objectForKey:@"venues"];
    NSMutableArray *useVenues = [NSMutableArray array];
    for (id item in (NSArray *)[venues objectForKey:@"items"]) {
        NSDictionary *venue = (NSDictionary *)[item objectForKey:@"venue"];
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

- (void)requestDidFinishLoading:(BZFoursquareRequest *)request {
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [_delegate requestDidSending: [self convertResponse: self.response]];
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[error userInfo] objectForKey:@"errorDetail"] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark BZFoursquareSessionDelegate

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare {
    [_delegate didAuthorize];
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorInfo);
}

@end
