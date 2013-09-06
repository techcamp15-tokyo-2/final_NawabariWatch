//
//  Foursquare.h
//  NawabariWatch
//
//  Created by techcamp on 2013/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

@interface Foursquare : NSObject <BZFoursquareRequestDelegate, BZFoursquareSessionDelegate>{
    BZFoursquare        *foursquare_;
    BZFoursquareRequest *request_;
    NSDictionary        *meta_;
    NSArray             *notifications_;
    NSDictionary        *response_;
}
@property(nonatomic,readonly,strong) BZFoursquare *foursquare;
-(BOOL)isAuthenticated;
-(void)startAuthorization;
-(void)prepareForRequest;
-(void)cancelRequest;
-(NSDictionary*)getVenueHistory;
-(NSDictionary*)getcheckinHistory;
@end
