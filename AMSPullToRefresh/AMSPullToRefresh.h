//
//  AMSPullToRefresh.h
//  Pods
//
//  Created by 朱琨 on 16/5/29.
//
//

#import <UIKit/UIKit.h>

@class AMSPullToRefreshView;

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (AMSPullToRefresh)

@property (strong, nonatomic, readonly) AMSPullToRefreshView *pullToRefreshView;

- (void)addPullToRefreshActionHandler:(void (^)())handler;
- (void)stopPullToRefresh:(BOOL)animated;
- (void)triggerPullToRefresh:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
