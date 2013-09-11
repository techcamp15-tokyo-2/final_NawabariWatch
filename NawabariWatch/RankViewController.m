//
//  RankViewController.m
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/11.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "RankViewController.h"

@implementation RankViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 戻るボタンの設定
    [button setTitle:@"MAPに戻る" forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(self.view.frame.size.width - button.frame.size.width - 10,
                              10,
                              button.frame.size.width,
                              button.frame.size.height);
    [button addTarget:self action:@selector(buttonDidPush) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    // ランキングタイトル
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake((self.view.frame.size.width - 280)/2,
                                  75,
                                  280,
                                  42);
    titleLabel.font  = [UIFont boldSystemFontOfSize:40];
    titleLabel.text  = @"全国ランキング";
    titleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:titleLabel];
    
    // 順位ラベル
    for (int i = 0; i < 5; i++) {
        UILabel *rankLabel = [[UILabel alloc] init];
        rankLabel.frame = CGRectMake(40,
                                     130 + 32 * i,
                                     250,
                                     27);
        rankLabel.font  = [UIFont boldSystemFontOfSize:25];
        rankLabel.text  = [NSString stringWithFormat:@"%d位: Watch 300万坪", i + 1];
        rankLabel.textColor = [UIColor blackColor];
        [self.view addSubview:rankLabel];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonDidPush
{
    NSLog(@"ボタンが押されました");
    // 前画面に戻る
    [self dismissViewControllerAnimated:YES completion:^{
        // 完了時の処理をここに書きます
    }];
}

@end
