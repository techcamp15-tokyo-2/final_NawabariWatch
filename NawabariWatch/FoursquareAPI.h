//
//  Foursquare.h
//  NawabariWatch
//
//  Created by techcamp on 2013/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

@protocol FoursquareAPIDelegate
- (void)didAuthorize;
- (void)getVenueHistory:(NSDictionary *) response;
- (void)getSearchVenues:(NSDictionary *) response;
@end

@interface FoursquareAPI : NSObject <BZFoursquareRequestDelegate, BZFoursquareSessionDelegate>{
    BZFoursquare        *foursquare_;
    BZFoursquareRequest *request_;
    NSDictionary        *meta_;
    NSArray             *notifications_;
    NSDictionary        *response_;
    int                 responseType;
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
@end
enum {
    venueHistory = 0,
    searchVenues = 1
};