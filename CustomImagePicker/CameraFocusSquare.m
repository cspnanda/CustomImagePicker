//
//  CameraFocusSquare.m
//
//  Created by Prasanna Nanda on 6/11/15.
//  Copyright (c) 2015 iosrecipe. All rights reserved.
//

#import "CameraFocusSquare.h"
#import <QuartzCore/QuartzCore.h>

const float squareLength = 80.0f;
@implementation CameraFocusSquare

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self.layer setBorderWidth:2.0];
    [self.layer setCornerRadius:4.0];
    [self.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    CABasicAnimation* selectionAnimation = [CABasicAnimation
                                            animationWithKeyPath:@"borderColor"];
    selectionAnimation.toValue = (id)[ColorUtil colorFromHexString:@"#ff7f00" withAlpha:1.0].CGColor;
    selectionAnimation.repeatCount = 8;
    [self.layer addAnimation:selectionAnimation
                      forKey:@"selectionAnimation"];
    
  }
  return self;
}
@end