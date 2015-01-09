//
//  PhotoCell.h
//  CustomImagePicker
//
//  Created by C S P Nanda on 1/5/15.
//  Copyright (c) 2015 C S P Nanda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoCell : UICollectionViewCell
- (void) setAsset:(ALAsset *)asset;
-(void) performSelectionAnimations;
-(void) hideTick;
-(void) showTick;
@property(nonatomic, strong) ALAsset *asset;
@end