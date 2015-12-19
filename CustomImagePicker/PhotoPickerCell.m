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
-(void) performSelectionAnimations
{
  
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
- (void) setAsset:(PHAsset *)asset
{
  // 2
  _asset = asset;
  NSInteger retinaScale = [UIScreen mainScreen].scale;
  CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
  
  PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
  cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
  cropToSquare.networkAccessAllowed = YES;
  cropToSquare.synchronous = NO;
  CGFloat cropSideLength = MIN(asset.pixelWidth, asset.pixelHeight);
  CGRect square = CGRectMake(0, 0, cropSideLength, cropSideLength);
  CGRect cropRect = CGRectApplyAffineTransform(square,
                                               CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
                                                                          1.0 / asset.pixelHeight));
  
  cropToSquare.normalizedCropRect = cropRect;
  
  [[PHImageManager defaultManager]
   requestImageForAsset:(PHAsset *)asset
   targetSize:retinaSquare
   contentMode:PHImageContentModeAspectFit
   options:cropToSquare
   resultHandler:^(UIImage *result, NSDictionary *info) {
     self.photoImageView.image = result;
   }];
  
  
}
- (void) setImage:(UIImage *)image
{
  [self.photoImageView setImage:image];
}

@end