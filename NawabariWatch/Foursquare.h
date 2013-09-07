//
//  Foursquare.h
//  NawabariWatch
//
//  Created by techcamp on 2013/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

@protocol FoursquareDelegate;
@interface Foursquare : NSObject <BZFoursquareRequestDelegate, BZFoursquareSessionDelegate>{
    BZFoursquare        *foursquare_;
    BZFoursquareRequest *request_;
    NSDictionary        *meta_;
    NSArray             *notifications_;
    NSDictionary        *response_;
    int                 responseType;
}
@property(nonatomic,readonly,strong) BZFoursquare *foursquare;
@property (nonatomic, strong) id<FoursquareDelegate> delegate;
-(BOOL)isAuthenticated;
-(BOOL)startAuthorization;
-(BOOL)handleOpenURL:(NSURL *)url;
-(void)prepareForRequest;
-(void)cancelRequest;
-(void)requestVenueHistory;
-(void)requestCheckinHistory;
-(NSDictionary *) getResponse;
@end
enum {
    venueHistory = 0,
    SearchVenues = 1
};

@protocol FoursquareDelegate
- (void)requestDidSending:(NSDictionary *) response;
@end