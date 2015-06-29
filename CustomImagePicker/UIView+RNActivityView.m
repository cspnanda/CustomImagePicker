//
//  UIView+RNActivityView.m
//  HudDemo
//
//  Created by Romilson Nunes on 09/07/14.
//  Copyright (c) 2014 Matej Bukovinski. All rights reserved.
//

#import "UIView+RNActivityView.h"

#import <objc/runtime.h>
#import <objc/message.h>

#define RNLoadingHelperKey @"RNLoadingHelperKey"
#define RNDateLastUpadaKey @"RNDateLastUpadaKey"

@implementation UIView (RNActivityView)

- (void)rn_dealloc {
    [self destroyActivityView];
    
    //this calls original dealloc method
    [self rn_dealloc];
}


- (void)rn_didMoveToSuperview {
    if (!self.superview || !self.window) {
        [self destroyActivityView];
    }
    
    [self rn_didMoveToSuperview];
}

- (void)rn_willMoveToSuperview:(UIView *)newSuperview {
    
    if (!self.window) {
        [self rn_activityView].delegate = nil;
        
        [self destroyActivityView];
    }
    
    [self rn_willMoveToSuperview:newSuperview];
}

- (void) destroyActivityView {
    @synchronized(self) {
        if (self.rn_activityView) {
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self.rn_activityView];
            self.rn_activityView.delegate = nil;
            
            @try {
                [self.rn_activityView removeFromSuperview];
            }
            @catch (NSException *exception) {
            }
            
            [self setActivityView:nil];
        }
    }
}




-(RNActivityView *)rn_activityView {
    return  objc_getAssociatedObject(self, RNLoadingHelperKey);
}

- (void)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    
    Method originalMethod = class_getInstanceMethod([self class], originalSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod([self class],
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod([self class],
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}



#pragma mark - Public Methods

-(RNActivityView *)activityView {
    RNActivityView *activityView = objc_getAssociatedObject(self, RNLoadingHelperKey);
    
    if (!activityView) {
        activityView = [[RNActivityView alloc] initWithView:self];
        activityView.delegate = self;
        [self setActivityView:activityView];
        
        [self swizzleMethod:NSSelectorFromString(@"dealloc") withMethod:@selector(rn_dealloc)];
        [self swizzleMethod:NSSelectorFromString(@"didMoveToSuperview") withMethod:@selector(rn_didMoveToSuperview)];
        [self swizzleMethod:NSSelectorFromString(@"willMoveToSuperview") withMethod:@selector(rn_willMoveToSuperview:)];
        
        
        
    }
    if (!activityView.superview) {
        [self addSubview:activityView];
    }
    return activityView;
}

-(void)setActivityView:(RNActivityView *)activityView {
    objc_setAssociatedObject(self, RNLoadingHelperKey, activityView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)showActivityView {
    [self.activityView show:YES];
}

-(void)showActivityViewWithLabel:(NSString *)text {
    [self showActivityViewWithLabel:text detailLabel:nil];
}

-(void)showActivityViewWithLabel:(NSString *)text detailLabel:(NSString *)detail {
    [self showActivityViewWithMode:self.activityView.mode label:text detailLabel:detail];
}

-(void)showActivityViewWithMode:(RNActivityViewMode)mode label:(NSString *)text detailLabel:(NSString *)detail; {
    
    [self.activityView setupDefaultValues];
    self.activityView.labelText = text;
    self.activityView.detailsLabelText = detail;
    self.activityView.mode = mode;
    self.activityView.dimBackground = NO;
    
    [self showActivityView];
}

-(void)showActivityViewWithMode:(RNActivityViewMode)mode label:(NSString *)text detailLabel:(NSString *)detail whileExecuting:(SEL)method onTarget:(id)target {
    
    [self.activityView setupDefaultValues];
    self.activityView.labelText = text;
    self.activityView.detailsLabelText = detail;
    self.activityView.mode = mode;
    self.activityView.dimBackground = YES;
    
    [self.activityView showWhileExecuting:method onTarget:target withObject:nil animated:YES];
}

-(void)showActivityViewWithMode:(RNActivityViewMode)mode label:(NSString *)text detailLabel:(NSString *)detail whileExecutingBlock:(dispatch_block_t)block {
    
    [self.activityView setupDefaultValues];
    self.activityView.labelText = text;
    self.activityView.detailsLabelText = detail;
    self.activityView.mode = mode;
    self.activityView.dimBackground = YES;
    
    [self.activityView showAnimated:YES whileExecutingBlock:block];
}


- (void) showActivityViewWithLabel:(NSString *)text image:(UIImage *)image {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self showActivityViewWithLabel:text customView:imageView];
}


- (void) showActivityViewWithLabel:(NSString *)text customView:(UIView *)view {
    [self.activityView setupDefaultValues];
    self.activityView.customView = view;
	self.activityView.mode = RNActivityViewModeCustomView;
    self.activityView.labelText = text;
    
    [self showActivityView];
}


- (void) hideActivityView {
    [self hideActivityViewWithAfterDelay:0];
}

- (void) hideActivityViewWithAfterDelay:(NSTimeInterval)delay {
    [self.activityView hide:YES afterDelay:delay];
}



#pragma mark -
#pragma mark RNActivityViewDelegate methods

- (void)hudWasHidden:(RNActivityView *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
	self.activityView = nil;
}



@end
