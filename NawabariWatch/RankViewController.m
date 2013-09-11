//
//  RankViewController.m
//  NawabariWatch
//
//  Created by Nao Minami on 13/09/11.
//  Copyright (c) 2013年 Nao Minami. All rights reserved.
//

#import "RankViewController.h"


@implementation RankViewController

- (id)init
{
    self = [super init];
    if (self) {
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *rankView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    rankView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    self.view = rankView;

    // 戻るボタンの設定
    [button setTitle:@"MAPに戻る" forState:UIControlStateNormal];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.numberOfLines = 2;
    button.frame = CGRectMake(192, 4, 122, 72);
    [button addTarget:self action:@selector(buttonDidPush) forControlEvents: UIControlEventTouchUpInside];
    [rankView addSubview:button];
    
    UIView *rankSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 90, self.view.frame.size.width - 90, self.view.frame.size.height)];
    
    // ランキングタイトル
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake((self.view.frame.size.width - 280)/2,
                                  0,
                                  280,
                                  42);
    titleLabel.font  = [UIFont boldSystemFontOfSize:40];
    titleLabel.text  = @"全国ランキング";
    titleLabel.textColor = [UIColor blackColor];
    [rankSubView addSubview:titleLabel];
    
    // 順位ラベル
    for (int i = 0; i < 5; i++) {
        UILabel *rankLabel = [[UILabel alloc] init];
        rankLabel.frame = CGRectMake(40,
                                     55 + 32 * i,
                                     250,
                                     27);
        rankLabel.font  = [UIFont boldSystemFontOfSize:25];
        rankLabel.text  = [NSString stringWithFormat:@"%d位: nyama %d万坪", i + 1, 50 * (6-i)];
        if (i == 1) {
           rankLabel.text  = [NSString stringWithFormat:@"%d位: watch 250万坪", i + 1]; 
        }
        rankLabel.textColor = [UIColor blackColor];
        [rankSubView addSubview:rankLabel];
    }
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.font  = [UIFont boldSystemFontOfSize:32];
    messageLabel.text  = @"1位まであと少し。";
    [messageLabel sizeToFit];
    messageLabel.frame = CGRectMake((self.view.frame.size.width - messageLabel.frame.size.width)/2,
                                  235,
                                  messageLabel.frame.size.width,
                                  messageLabel.frame.size.height);
    messageLabel.textColor = [UIColor blackColor];
    [rankSubView addSubview:messageLabel];
    
    [rankView addSubview:rankSubView];
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
