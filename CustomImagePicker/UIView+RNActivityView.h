//
//  UIView+RNActivityView.h
//  HudDemo
//
//  Created by Romilson Nunes on 09/07/14.
//  Copyright (c) 2014 Matej Bukovinski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RNActivityView.h"


@interface UIView (RNActivityView)<RNActivityViewDelegate>

@property(nonatomic, readonly) RNActivityView * activityView;


-(void)showActivityView;
-(void)showActivityViewWithLabel:(NSString *)text;
-(void)showActivityViewWithLabel:(NSString *)text detailLabel:(NSString *)detail;
-(void)showActivityViewWithMode:(RNActivityViewMode)mode label:(NSString *)text detailLabel:(NSString *)detail;

-(void)showActivityViewWithMode:(RNActivityViewMode)mode label:(NSString *)text detailLabel:(NSString *)detail whileExecuting:(SEL)method onTarget:(id)target;

-(void)showActivityViewWithMode:(RNActivityViewMode)mode label:(NSString *)text detailLabel:(NSString *)detail whileExecutingBlock:(dispatch_block_t)block;


- (void) hideActivityView;
- (void) hideActivityViewWithAfterDelay:(NSTimeInterval)delay;

- (void) showActivityViewWithLabel:(NSString *)text image:(UIImage *)image;
- (void) showActivityViewWithLabel:(NSString *)text customView:(UIView *)view;



@end
