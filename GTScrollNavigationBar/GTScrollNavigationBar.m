//
//  GTScrollNavigationBar.m
//  GTScrollNavigationBarExample
//
//  Created by Luu Gia Thuy on 21/12/13.
//  Copyright (c) 2013 Luu Gia Thuy. All rights reserved.
//

#import "GTScrollNavigationBar.h"

#define kNavigationBarHeightPortrait 44.0f
#define kNavigationBarHeightLandscape 32.0f

@interface GTScrollNavigationBar () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;
@property (assign, nonatomic) CGFloat lastContentOffsetY;

@end

@implementation GTScrollNavigationBar

@synthesize scrollView = _scrollView,
            scrollState = _scrollState,
            panGesture = _panGesture,
            lastContentOffsetY = _lastContentOffsetY;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(handlePan:)];
        self.panGesture.delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarOrientationDidChange)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

- (void)setScrollView:(UIScrollView*)scrollView
{
    _scrollView = scrollView;
    
    CGRect defaultFrame = self.frame;
    defaultFrame.origin.y = [self statusBarHeight];
    [self setFrame:defaultFrame alpha:1.0f animated:NO];
    
    // remove gesture from current panGesture's view
    if (self.panGesture.view) {
        [self.panGesture.view removeGestureRecognizer:self.panGesture];
    }
    
    if (scrollView) {
        [scrollView addGestureRecognizer:self.panGesture];
    }
}

- (void)resetToDefaultPosition:(BOOL)animated
{
    CGRect frame = self.frame;
    frame.origin.y = [self statusBarHeight];
    [self setFrame:frame alpha:1.0f animated:NO];
}

#pragma mark - notification
- (void)statusBarOrientationDidChange
{
    [self setFrame:self.frame alpha:1.0f animated:NO];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - panGesture handler
- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
    if (!self.scrollView || gesture.view != self.scrollView)
        return;
    
    CGFloat contentOffsetY = self.scrollView.contentOffset.y;
    
    if (contentOffsetY < 0.0f)
        return;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.scrollState = GTScrollNavigationBarNone;
        self.lastContentOffsetY = contentOffsetY;
        return;
    }
    
    CGFloat deltaY = contentOffsetY - self.lastContentOffsetY;
    if (deltaY < 0.0f) {
        self.scrollState = GTScrollNavigationBarScrollingDown;
    } else if (deltaY > 0.0f) {
        self.scrollState = GTScrollNavigationBarScrollingUp;
    }
    
    CGRect frame = self.frame;
    float alpha = 1.0f;
    CGFloat maxY = [self statusBarHeight];
    CGFloat minY = maxY - [self defaultNavigationBarHeight];
    
    bool isScrollingAndGestureEnded = (gesture.state == UIGestureRecognizerStateEnded ||
                                       gesture.state == UIGestureRecognizerStateCancelled) &&
                                        (self.scrollState == GTScrollNavigationBarScrollingUp ||
                                         self.scrollState == GTScrollNavigationBarScrollingDown);
    if (isScrollingAndGestureEnded) {
        CGFloat contentOffsetYDelta = 0.0f;
        if (self.scrollState == GTScrollNavigationBarScrollingDown) {
            contentOffsetYDelta = maxY - frame.origin.y;
            frame.origin.y = maxY;
            alpha = 1.0f;
        }
        else if (self.scrollState == GTScrollNavigationBarScrollingUp) {
            contentOffsetYDelta = minY - frame.origin.y;
            frame.origin.y = minY;
            alpha = 0.000001f;
        }
        
        [self setFrame:frame alpha:alpha animated:YES];
        
        if (!self.scrollView.decelerating) {
            CGPoint newContentOffset = CGPointMake(self.scrollView.contentOffset.x,
                                                   contentOffsetY - contentOffsetYDelta);
            [self.scrollView setContentOffset:newContentOffset animated:YES];
        }
    }
    else {
        frame.origin.y -= deltaY;
        frame.origin.y = MIN(maxY, MAX(frame.origin.y, minY));
        
        alpha = (frame.origin.y - minY) / (maxY - minY);
        alpha = MAX(0.000001f, alpha);
        
        [self setFrame:frame alpha:alpha animated:NO];
    }
    
    self.lastContentOffsetY = contentOffsetY;
}

#pragma mark - helper methods
- (CGFloat)statusBarHeight
{
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectGetWidth([UIApplication sharedApplication].statusBarFrame);
        default:
            break;
    };
    return 0.0f;
}

- (CGFloat)defaultNavigationBarHeight
{
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            return kNavigationBarHeightPortrait;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return kNavigationBarHeightLandscape;
        default:
            break;
    };
    return 0.0f;
}

- (void)setFrame:(CGRect)frame alpha:(CGFloat)alpha animated:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:@"GTScrollNavigationBarAnimation" context:nil];
    }
    
    for (UIView* view in self.subviews) {
        bool isBackgroundView = view == [self.subviews objectAtIndex:0];
        bool isViewHidden = view.hidden || view.alpha == 0.0f;
        if (isBackgroundView || isViewHidden)
            continue;
        view.alpha = alpha;
    }
    self.frame = frame;
    
    if (animated) {
        [UIView commitAnimations];
    }
}

@end
