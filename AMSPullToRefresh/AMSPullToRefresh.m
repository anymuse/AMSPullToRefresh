//
//  AMSPullToRefresh.m
//  Pods
//
//  Created by 朱琨 on 16/5/29.
//
//

#import "AMSPullToRefresh.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, AMSPullToRefreshState) {
    AMSPullToRefreshStateIdle,
    AMSPullToRefreshStateCanBeTriggered,
    AMSPullToRefreshStateWillBeTriggered,
    AMSPullToRefreshStateRefreshing,
    AMSPullToRefreshStateRestoring
};

static void * AMSScrollViewContentOffsetObserverContext = &AMSScrollViewContentOffsetObserverContext;
static void * AMSScrollViewContentInsetObserverContext = &AMSScrollViewContentInsetObserverContext;

static NSString * const kContentOffsetKey = @"contentOffset";
static NSString * const kContentInsetKey = @"contentInset";
static NSString * const kContentSizeKey = @"contentSize";

static CGFloat const kBottomPadding = 5.0;
static CGFloat const kThresholdOffset = 50.0;
static CGFloat const kInitialTopInset = 64.0;
static CGFloat const kHeightOfPullToRefreshView = 50.0;

#pragma mark - AMSPullToRefreshView
@interface AMSPullToRefreshView : UIView

@property (assign, nonatomic) AMSPullToRefreshState state;
@property (assign, nonatomic) CGFloat originalTopInset;
@property (assign, nonatomic) CGFloat lastOffset;
@property (assign, nonatomic, getter=isObserving) BOOL observing;
@property (copy, nonatomic) void (^actionHandler)();
@property (strong, nonatomic) UILabel *stateLabel;
@property (weak, nonatomic) UIScrollView *scrollView;

- (void)actionTriggered:(BOOL)animated;
- (void)actionFinished:(BOOL)animated;
- (void)setupScrollViewContentInsetForRefreshingState:(BOOL)animated completion:(void (^)())completion;
- (void)resetScrollViewContentInset:(BOOL)animated completion:(void (^)())completion;

@end

@implementation AMSPullToRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self setupViews];
}

- (void)setupViews {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _stateLabel = [UILabel new];
    _stateLabel.textColor = [UIColor lightGrayColor];
    _stateLabel.textAlignment = NSTextAlignmentCenter;
    _stateLabel.font = [UIFont systemFontOfSize:13];
    _stateLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_stateLabel];
    self.state = AMSPullToRefreshStateIdle;
}

- (void)layoutSubviews {
    self.stateLabel.center = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) - CGRectGetHeight(self.stateLabel.frame) / 2 - kBottomPadding);
}

- (void)addObserversForScrollView:(UIScrollView *)scrollView {
    [scrollView addObserver:self forKeyPath:kContentOffsetKey options:NSKeyValueObservingOptionNew context:AMSScrollViewContentOffsetObserverContext];
    [scrollView addObserver:self forKeyPath:kContentInsetKey options:NSKeyValueObservingOptionNew context:AMSScrollViewContentInsetObserverContext];
    self.observing = YES;
}

- (void)removeObserversForScrollView:(UIScrollView *)scrollView {
    [scrollView removeObserver:self forKeyPath:kContentOffsetKey];
    [scrollView removeObserver:self forKeyPath:kContentInsetKey];
    self.observing = NO;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && self.isObserving) {
        [self removeObserversForScrollView:(UIScrollView *)self.superview];
    }
    
    if (newSuperview) {
        [self addObserversForScrollView:(UIScrollView *)newSuperview];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == AMSScrollViewContentOffsetObserverContext) {
        [self scrollViewDidScroll:[change[NSKeyValueChangeNewKey] CGPointValue]];
    } else if (context == AMSScrollViewContentInsetObserverContext) {
        CGFloat topInset = [change[NSKeyValueChangeNewKey] UIEdgeInsetsValue].top;
        self.originalTopInset = topInset;
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    CGFloat offsetY = contentOffset.y;
    switch (_state) {
        case AMSPullToRefreshStateIdle: {
            if (self.scrollView.isDragging && (offsetY + self.originalTopInset <= -kThresholdOffset)) {
                self.state = AMSPullToRefreshStateCanBeTriggered;
            }
        } break;
        case AMSPullToRefreshStateCanBeTriggered: {
            if (self.scrollView.isDragging) {
                if (offsetY + self.originalTopInset > -kThresholdOffset) {
                    self.state = AMSPullToRefreshStateIdle;
                }
            } else {
                self.lastOffset = MIN(-(self.originalTopInset + kThresholdOffset), offsetY);
                self.state = AMSPullToRefreshStateWillBeTriggered;
                self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x
                                                            , self.lastOffset);
            }
        } break;
        case AMSPullToRefreshStateWillBeTriggered: {
            if (!self.scrollView.isDragging) {
                if (_lastOffset <= offsetY) {
                    [self actionTriggered:YES];
                }
                self.lastOffset = offsetY;
            }
        } break;
        case AMSPullToRefreshStateRefreshing: {
            CGRect frame = self.frame;
            frame.origin.y = MIN(offsetY + kInitialTopInset, -kHeightOfPullToRefreshView);
            self.frame = frame;
        } break;
        case AMSPullToRefreshStateRestoring: {
        } break;
    }
}

#pragma mark - Action
- (void)actionTriggered:(BOOL)animated {
    if (_state == AMSPullToRefreshStateRefreshing) {
        return;
    }
    self.state = AMSPullToRefreshStateRefreshing;
    [self setupScrollViewContentInsetForRefreshingState:animated completion:^{
        if (self.actionHandler) {
            self.actionHandler();
        }
    }];
}

- (void)actionFinished:(BOOL)animated {
    if (_state == AMSPullToRefreshStateRestoring || _state == AMSPullToRefreshStateIdle) {
        return;
    }
    
    self.state = AMSPullToRefreshStateRestoring;
    [self resetScrollViewContentInset:animated completion:^{
        self.lastOffset = self.scrollView.contentOffset.y;
        self.state = AMSPullToRefreshStateIdle;
    }];
}

#pragma mark - Scroll View ContentInset
- (void)setupScrollViewContentInsetForRefreshingState:(BOOL)animated completion:(void (^)())completion {
    UIEdgeInsets currentInset = self.scrollView.contentInset;
    currentInset.top += kHeightOfPullToRefreshView;
    [self setScrollViewContentInset:currentInset animated:animated completion:completion];
}

- (void)resetScrollViewContentInset:(BOOL)animated completion:(void (^)())completion {
    UIEdgeInsets currentInset = self.scrollView.contentInset;
    currentInset.top -= kHeightOfPullToRefreshView;
    [self setScrollViewContentInset:currentInset animated:animated completion:completion];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset animated:(BOOL)animated completion:(void (^)())completion {
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                         if (_state == AMSPullToRefreshStateRestoring) {
                             self.frame = CGRectMake(0, -kHeightOfPullToRefreshView, CGRectGetWidth(self.frame), kHeightOfPullToRefreshView);
                         }
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                             completion();
                         }
                     }];
    if (_state == AMSPullToRefreshStateRefreshing) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -contentInset.top) animated:animated];
    }
}

#pragma mark - Getters & Setters
- (void)setState:(AMSPullToRefreshState)state {
    if (_state == state) {
        return;
    }
    _state = state;
    switch (state) {
        case AMSPullToRefreshStateIdle: {
            self.scrollView.scrollEnabled = YES;
            self.stateLabel.text = @"下拉刷新";
        } break;
        case AMSPullToRefreshStateCanBeTriggered: {
            self.stateLabel.text = @"松开刷新";
        } break;
        case AMSPullToRefreshStateWillBeTriggered: {
        } break;
        case AMSPullToRefreshStateRefreshing: {
            self.stateLabel.text = @"刷新中...";
        } break;
        case AMSPullToRefreshStateRestoring: {
            self.scrollView.scrollEnabled = NO;
        } break;
    }
    [self.stateLabel sizeToFit];
}

@end

#pragma mark - AMSPullToRefresh
@interface UIScrollView ()

@property (strong, nonatomic) AMSPullToRefreshView *pullToRefreshView;

@end

@implementation UIScrollView (AMSPullToRefresh)

- (void)addPullToRefreshActionHandler:(void (^)())handler {
    if (!self.pullToRefreshView) {
        self.pullToRefreshView = [[AMSPullToRefreshView alloc] initWithFrame:CGRectMake(0, -kHeightOfPullToRefreshView, CGRectGetWidth(self.bounds), kHeightOfPullToRefreshView)];
        self.pullToRefreshView.scrollView = self;
        self.pullToRefreshView.originalTopInset = self.contentInset.top;
        self.pullToRefreshView.actionHandler = handler;
        [self addSubview:self.pullToRefreshView];
        [self sendSubviewToBack:self.pullToRefreshView];
    }
}

#pragma mark - Public Method
- (void)triggerPullToRefresh:(BOOL)animated {
    [self.pullToRefreshView actionTriggered:animated];
}

- (void)stopPullToRefresh:(BOOL)animated {
    [self.pullToRefreshView actionFinished:animated];
}

#pragma mark - Getters & Setters
- (AMSPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPullToRefreshView:(AMSPullToRefreshView *)pullToRefreshView {
    objc_setAssociatedObject(self, @selector(pullToRefreshView), pullToRefreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
