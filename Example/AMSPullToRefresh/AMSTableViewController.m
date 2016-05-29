//
//  AMSTableViewController.m
//  AMSPullToRefresh
//
//  Created by 朱琨 on 16/5/29.
//  Copyright © 2016年 anymuse. All rights reserved.
//

#import "AMSTableViewController.h"
#import <AMSPullToRefresh.h>

@interface AMSTableViewController ()

@end

@implementation AMSTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tableFooterView.frame = CGRectMake(0, 0, 0, 0.1);
    
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    UIEdgeInsets contentInset = self.tableView.contentInset;
//    contentInset.top = 64;
//    self.tableView.contentInset = contentInset;
    
    __weak __typeof(self)weakSelf = self;
    [self.tableView addPullToRefreshActionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.tableView stopPullToRefresh:YES];
        });
    }];
    
    /**
     *  If you set automaticallyAdjustsScrollViewInsets ot NO,
     */
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    UIEdgeInsets contentInset = self.tableView.contentInset;
//    contentInset.top = 64;
//    self.tableView.contentInset = contentInset;
    
    
    [self.tableView triggerPullToRefresh:YES];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = @"拉一下试试啦！~";
    return cell;
}

@end
