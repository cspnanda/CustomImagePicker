//
//  PhotoCell.h
//  CustomImagePicker
//
//  Created by Prasanna Nanda on 1/5/15.
//  Copyright (c) 2015 Prasanna Nanda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Header.h"

@interface PhotoPickerCell : UICollectionViewCell
- (void) setAsset:(ALAsset *)asset;
- (void) setImage:(UIImage *)image;
- (UIImageView*) getImageView;
-(void) performSelectionAnimations;
-(void) hideTick;
-(void) showTick;
@property(nonatomic, strong) ALAsset *asset;
@end