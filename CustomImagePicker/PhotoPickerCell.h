//
//  PhotoCell.h
//  CustomImagePicker
//
//  Created by Prasanna Nanda on 1/5/15.
//  Copyright (c) 2015 Prasanna Nanda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Header.h"
@import Photos;

@interface PhotoPickerCell : UICollectionViewCell
- (void) setAsset:(PHAsset *)asset;
- (void) setImage:(UIImage *)image;
- (UIImageView*) getImageView;
-(void) performSelectionAnimations;
-(void) hideTick;
-(void) showTick;
@property(nonatomic, strong) PHAsset *asset;
@end