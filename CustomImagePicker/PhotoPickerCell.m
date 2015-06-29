//
//  PhotoCell.m
//  CustomImagePicker
//
//  Created by Prasanna Nanda on 1/5/15.
//  Copyright (c) 2015 Prasanna Nanda. All rights reserved.
//

#import "PhotoPickerCell.h"

@interface PhotoPickerCell ()
// 1
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@property(nonatomic, weak) IBOutlet UIImageView *tickView;

@end

@implementation PhotoPickerCell
- (UIImageView*) getImageView;
{
  return self.photoImageView;
}
- (id)initWithFrame:(CGRect)frame {
  
  self = [super initWithFrame:frame];
  
  if (self) {
    // Initialization code
    NSArray *arrayOfViews = Nil;
    if(IS_IPHONE_6||IS_IPHONE_6P)
      arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"PhotoPickerCell" owner:self options:nil];
    else
      arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"PhotoPickerCell_5" owner:self options:nil];
    
    
    if ([arrayOfViews count] < 1) {
      return nil;
    }
    
    if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) {
      return nil;
    }
    
    self = [arrayOfViews objectAtIndex:0];
    
  }
  
  return self;
  
}

-(void) showTick
{
  [self.tickView setHidden:NO];
}
-(void) hideTick
{
  [self.tickView setHidden:YES];
}
- (void) setAsset:(ALAsset *)asset
{
  // 2
  _asset = asset;
  self.photoImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
}
- (void) setImage:(UIImage *)image
{
  [self.photoImageView setImage:image];
}
@end