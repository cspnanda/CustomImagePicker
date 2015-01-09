//
//  CustomeImagePicker.m
//  CustomImagePicker
//
//  Created by C S P Nanda on 1/5/15.
//  Copyright (c) 2015 C S P Nanda. All rights reserved.
//

#import "CustomeImagePicker.h"

@interface CustomeImagePicker ()
@property(nonatomic, strong) NSArray *assets;
@property(nonatomic,strong) UIImage *selectedImage;

@end

@implementation CustomeImagePicker
- (void)viewDidLoad
{
  [super viewDidLoad];
  //  UINib *cellNib = [UINib nibWithNibName:@"PhotoCell" bundle:nil];
  //  [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"PhotoCell"];
  [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
  UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
  [flowLayout setItemSize:CGSizeMake(100, 100)];
  [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
  [self.collectionView setCollectionViewLayout:flowLayout];
  _assets = [@[] mutableCopy];
  __block NSMutableArray *tmpAssets = [@[] mutableCopy];
  
  
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    ALAsset *asset = [[ALAsset alloc] init];
    [tmpAssets insertObject:asset atIndex:0];
  }
  
  
  
  // 1
  ALAssetsLibrary *assetsLibrary = [CustomeImagePicker defaultAssetsLibrary];
  // 2
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    //    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
    //      if(result)
    //      {
    //        // 3
    //        [tmpAssets addObject:result];
    //      }
    //    }];
    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if(result)
      {
        [tmpAssets addObject:result];
      }
    }
     ];
    
    // 4
    //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    //self.assets = [tmpAssets sortedArrayUsingDescriptors:@[sort]];
    self.assets = tmpAssets;
    
    // 5
    [self.collectionView reloadData];
  } failureBlock:^(NSError *error) {
    NSLog(@"Error loading images %@", error);
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}
- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return self.assets.count;
}
-(void) showCamera
{
  NSLog(@"Camera Selected");
}
- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"PhotoCell";
  PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
  
  ALAsset *asset = self.assets[indexPath.row];
  cell.asset = asset;
  cell.backgroundColor = [UIColor whiteColor];
  if (self.selectedItemIndexPath != nil && [indexPath compare:self.selectedItemIndexPath] == NSOrderedSame) {
    cell.layer.borderColor = [[UIColor orangeColor] CGColor];
    cell.layer.borderWidth = 4.0;
  } else {
    cell.layer.borderColor = nil;
    cell.layer.borderWidth = 0.0;
  }
  
  return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 4;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 1;
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
  static dispatch_once_t pred = 0;
  static ALAssetsLibrary *library = nil;
  dispatch_once(&pred, ^{
    library = [[ALAssetsLibrary alloc] init];
  });
  return library;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:indexPath];
  
  if (self.selectedItemIndexPath)
  {
    // if we had a previously selected cell
    
    if ([indexPath compare:self.selectedItemIndexPath] == NSOrderedSame)
    {
      // if it's the same as the one we just tapped on, then we're unselecting it
      
      self.selectedItemIndexPath = nil;
    }
    else
    {
      // if it's different, then add that old one to our list of cells to reload, and
      // save the currently selected indexPath
      
      [indexPaths addObject:self.selectedItemIndexPath];
      self.selectedItemIndexPath = indexPath;
    }
  }
  else
  {
    // else, we didn't have previously selected cell, so we only need to save this indexPath for future reference
    
    self.selectedItemIndexPath = indexPath;
  }
  
  // and now only reload only the cells that need updating
  
  [collectionView reloadItemsAtIndexPaths:indexPaths];
  if(indexPath.row == 0 && indexPath.section == 0 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
  {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:NULL];
    
  }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  
  [picker dismissViewControllerAnimated:YES completion:NULL];
  
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  
  UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
  [picker dismissViewControllerAnimated:YES completion:^{
    self.selectedImage = chosenImage;
    [self dismissViewControllerAnimated:YES completion:^{
      if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
        [self.delegate imageSelected:self.selectedImage];
      }
    }];
    
  }
   ];
}
-(IBAction)donePressed:(id)sender
{
  if(self.selectedItemIndexPath == Nil)
  {
    NSLog(@"Please Select One");
  }
  else
  {
    PhotoCell *cell = (PhotoCell*)[self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
    // NSLog(@"URL = %@",cell.asset.defaultRepresentation.url);
    
    
    ALAssetRepresentation *rep = [cell.asset defaultRepresentation];
    CGImageRef iref = [rep fullResolutionImage];
    if(iref)
    {
      self.selectedImage = [UIImage imageWithCGImage:iref];
      [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
          [self.delegate imageSelected:self.selectedImage];
        }
      }];
    }
  }
}

-(IBAction)cancelPressed:(id)sender
{
  self.selectedImage = Nil;
  [self dismissViewControllerAnimated:YES completion:^{
    if ([self.delegate respondsToSelector:@selector(imageSelectionCancelled)]) {
    }
  }];
  
}


//-(IBAction)photoSelected:(id)sender
//{
//
//  [self dismissViewControllerAnimated:YES completion:^{
//    if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
//      [self.delegate imageSelected:self.selectedImage];
//    }
//    // [self.imageSelectedView removeFromSuperview];
//  }];
//}

//-(IBAction)cancelSelectedPhoto:(id)sender
//{
//  // [self.imageSelectedView removeFromSuperview];
//}



@end
