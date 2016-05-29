//
//  AMSPullToRefresh.h
//  Pods
//
//  Created by 朱琨 on 16/5/29.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (AMSPullToRefresh)

- (void)addPullToRefreshActionHandler:(void (^)())handler;
- (void)triggerPullToRefresh:(BOOL)animated;
- (void)stopPullToRefresh:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
