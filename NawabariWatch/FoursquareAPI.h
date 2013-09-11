//
//  Foursquare.h
//  NawabariWatch
//
//  Created by techcamp on 2013/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

#define LIMIT_TIME 30
#define LIMIT_CHECKIN 100
#define MAX_OFFSET 100

@protocol FoursquareAPIDelegate
- (void)didAuthorize;
- (void)getVenueHistory:(NSDictionary *) response;
- (void)getSearchVenues:(NSDictionary *) response;
- (void)getCheckin:(NSDictionary *) response;
- (void)getUserProfile:(NSDictionary *) response;
- (void)getCheckinHistory:(NSDictionary *)response;
@end

@interface FoursquareAPI : NSObject <BZFoursquareRequestDelegate, BZFoursquareSessionDelegate>{
    BZFoursquare        *foursquare_;
    BZFoursquareRequest *request_;
    NSDictionary        *meta_;
    NSArray             *notifications_;
    NSMutableDictionary *response;
    int                 responseType_;
    int                 offset_;
    NSTimeInterval      limitTime;
}

@property(nonatomic,readonly,strong) BZFoursquare *foursquare;
@property (nonatomic, strong) id<FoursquareAPIDelegate> delegate;
-(BOOL)isAuthenticated;
-(BOOL)startAuthorization;
-(BOOL)handleOpenURL:(NSURL *)url;
-(void)prepareForRequestWithType:(int)type;
-(void)cancelRequest;
-(void)requestVenueHistory;
-(void)requestSearchVenuesWithLatitude:(double)lat Longitude:(double)lng;
-(void)requestCheckin:(NSString *)venueId;
-(void) requestUserProfile;
-(void)requestCheckinHistoryFirst;
@end
enum {
    venueHistory = 0,
    searchVenues,
    userProfile,
    checkin,
    checkinHistory
};