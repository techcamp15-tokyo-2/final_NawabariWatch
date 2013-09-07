//
//  NawabariViewController+Location.m
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/06.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "NawabariViewController.h"

@implementation NawabariViewController (Location)

// 位置情報が取得成功した場合にコールされる
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
	// 位置情報更新
	_longitude = newLocation.coordinate.longitude;
	_latitude  = newLocation.coordinate.latitude;
}

// 位置情報が取得失敗した場合にコールされる。
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (error) {
		NSString* message = nil;
		switch ([error code]) {
                // アプリでの位置情報サービスが許可されていない場合
			case kCLErrorDenied:
				// 位置情報取得停止
				[locationManager stopUpdatingLocation];
				message = [NSString stringWithFormat:@"このアプリは位置情報サービスが許可されていません。"];
				break;
			default:
				message = [NSString stringWithFormat:@"位置情報の取得に失敗しました。"];
				break;
		}
		if (message) {
			// アラートを表示
			UIAlertView* alert=[[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil
                                                cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
}

@end
