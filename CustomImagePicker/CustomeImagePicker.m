//
//  CustomeImagePicker.m
//  CustomImagePicker
//
//  Created by Prasanna Nanda on 1/5/15.
//  Copyright (c) 2015 Prasanna Nanda. All rights reserved.
//

#import "CustomeImagePicker.h"
#import "UIView+RNActivityView.h"
@import Photos;
@import PhotosUI;

@interface CustomeImagePicker ()
@property(nonatomic, strong) NSMutableArray *assets;
@end

@implementation CustomeImagePicker
@synthesize whereamI,skipButton,nextButton,hideNextButton,hideSkipButton,highLightThese,maxPhotos,distanceFromButton,nearByCollectionView,currentUserLocation,showOnlyPhotosWithGPS,howMany;

/* View Delegate Methods */

-(void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if(highLightThese == Nil)
    highLightThese = [[NSMutableArray alloc] init];
  
}
-(void) viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [session stopRunning];
}
-(void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.1];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if(hideSkipButton)
  {
    [skipButton setHidden:YES];
  }
  if(hideNextButton)
  {
    [nextButton setHidden:YES];
  }
  if([highLightThese count]>=1)
    [nextButton setHidden:NO];
  else
    [nextButton setHidden:YES];
  [self.collectionView registerClass:[PhotoPickerCell class] forCellWithReuseIdentifier:@"PhotoPickerCell"];
  [self.collectionView registerClass:[CameraCell class] forCellWithReuseIdentifier:@"CameraCell"];
  
  UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
  if(IS_IPHONE_6 || IS_IPHONE_6P)
    [flowLayout setItemSize:CGSizeMake(120, 120)];
  else
    [flowLayout setItemSize:CGSizeMake(100, 100)];
  [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
  [self.collectionView setCollectionViewLayout:flowLayout];
  self.assets = [[NSMutableArray alloc] init];
  
  totalNumberOfPhotos = 0;
  lastNumber = 0;
  hasReachedEnd = NO;
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
  if(status == PHAuthorizationStatusAuthorized) {
    if(hasReachedEnd == NO)
      [self loadPhoto];
  }
  else if(status == PHAuthorizationStatusNotDetermined) {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
      if(authorizationStatus == PHAuthorizationStatusAuthorized) {
        if(hasReachedEnd == NO)
          [self loadPhoto];
      }
    }];
  }
  else if(status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied) {
    [self photoRollAccessDisabled];
  }
}

/* Error Handling Functions */

-(void) cameraAccessDisabled {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Camera Access Diabled" message:@"Trumbs can't access Your Camera. Tap Settings Now to allow access to Camera" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
    [alertView show];
    [alertView release];
  });
}

-(void) photoRollAccessDisabled {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Photo Access Diabled" message:@"Trumbs can't access Your Photos. Tap Settings Now to allow access to Photos" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
    [alertView show];
    [alertView release];
  });
}
-(BOOL) checkForCamera
{
  AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if(authStatus == AVAuthorizationStatusAuthorized) {
    // do your logic
    return YES;
  }
  return NO;
}


- (void)displayErrorOnMainQueue:(NSString*) heading message:(NSString *)message
{
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:heading
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  });
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if(buttonIndex == 1) {
    [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
  }
}



/* CollectionView Delegate Methods */
- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"PhotoPickerCell";
  static NSString *cameraCellIdentifier = @"CameraCell";
  if(indexPath.row == 0)
  {
    if(showOnlyPhotosWithGPS == YES) {
      // This is From Tab 2
      PhotoPickerCell *cell = (PhotoPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
      PHAsset *asset = self.assets[indexPath.row];
      NSString *assetURL = [NSString stringWithFormat:@"asset-library://%@",asset.localIdentifier];
      cell.asset = asset;
      cell.backgroundColor = [UIColor whiteColor];
      if([highLightThese containsObject:assetURL])
      {
        cell.layer.borderColor = [[UIColor orangeColor] CGColor];
        cell.layer.borderWidth = 4.0;
        [cell setAlpha:1.0];
        [cell setUserInteractionEnabled:YES];
      }
      else
      {
        if([highLightThese count] == maxPhotos)
        {
          cell.layer.borderColor = nil;
          cell.layer.borderWidth = 0.0;
          [cell setAlpha:0.5];
          [cell setUserInteractionEnabled:NO];
        }
        else
        {
          cell.layer.borderColor = nil;
          cell.layer.borderWidth = 0.0;
          [cell setAlpha:1.0];
          [cell setUserInteractionEnabled:YES];
        }
      }
      return cell;
    }
    else {
      // This is Normal
      CameraCell *cell = (CameraCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cameraCellIdentifier forIndexPath:indexPath];
      cell.backgroundColor = [UIColor whiteColor];
      return cell;
    }
  } // Cell No 0
  else
  {
    // Case 1
    NSUInteger rowNum = indexPath.row-1;
    if(showOnlyPhotosWithGPS == YES)
      rowNum++;
    PhotoPickerCell *cell = (PhotoPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    PHAsset *asset = self.assets[rowNum];
    NSString *assetURL = [NSString stringWithFormat:@"asset-library://%@",asset.localIdentifier];
    cell.asset = asset;
    cell.backgroundColor = [UIColor whiteColor];
    if([highLightThese containsObject:assetURL])
    {
      cell.layer.borderColor = [[UIColor orangeColor] CGColor];
      cell.layer.borderWidth = 4.0;
      [cell setAlpha:1.0];
      [cell setUserInteractionEnabled:YES];
    }
    else
    {
      if([highLightThese count] == maxPhotos)
      {
        cell.layer.borderColor = nil;
        cell.layer.borderWidth = 0.0;
        [cell setAlpha:0.5];
        [cell setUserInteractionEnabled:NO];
      }
      else
      {
        cell.layer.borderColor = nil;
        cell.layer.borderWidth = 0.0;
        [cell setAlpha:1.0];
        [cell setUserInteractionEnabled:YES];
      }
    }
    return cell;
  }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
  if (bottomEdge >= scrollView.contentSize.height) {
    if(hasReachedEnd == NO)
      [self loadPhoto];
  }
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 4;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 1;
}
-(void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
  PHAsset *asset = self.assets[indexPath.row];
  NSString *assetURL = asset.localIdentifier;
  
  if([highLightThese containsObject:assetURL])
  {
    [highLightThese removeObject:assetURL];
    [collectionView reloadData];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  UICollectionViewCell *cell = (UICollectionViewCell*) [collectionView cellForItemAtIndexPath:indexPath];
  if(indexPath.row == 0) {
    if(showOnlyPhotosWithGPS == YES) {
      PHAsset *asset = self.assets[indexPath.row];
      NSString *assetURL = [NSString stringWithFormat:@"asset-library://%@",asset.localIdentifier];
      
      
      if(![highLightThese containsObject:assetURL] && ([highLightThese count] < maxPhotos))
      {
        [highLightThese addObject:assetURL];
      }
      else
      {
        [highLightThese removeObject:assetURL];
      }
      if([highLightThese count]>=1)
        [nextButton setHidden:NO];
      else
        [nextButton setHidden:YES];
      [collectionView reloadData];
    }
    else {
      [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if(granted) {
          if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            YCameraViewController *ycv = [[YCameraViewController alloc] init];
            [ycv setDelegate:self];
            [ycv setCurrentUserLocation:currentUserLocation];
            [self presentViewController:ycv animated:YES completion:^{
            }];
          }
          else {
            dispatch_async(dispatch_get_main_queue(), ^{
              OLGhostAlertView *ghastly = [[OLGhostAlertView alloc] initWithTitle:@"Oops" message:@"Your device doesn't support camera" timeout:1.0 dismissible:YES];
              [ghastly show];
            });
          }
        }
        else {
          [self cameraAccessDisabled];
        }
      }];
    }
  }
  else {
    NSUInteger rowNum = indexPath.row-1;
    if(showOnlyPhotosWithGPS == YES)
      rowNum++;
    PHAsset *asset = self.assets[rowNum];
    NSString *assetURL = [NSString stringWithFormat:@"asset-library://%@",asset.localIdentifier];
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    if(![highLightThese containsObject:assetURL] && ([highLightThese count] < maxPhotos))
    {
      [highLightThese addObject:assetURL];
      assetURL = [highLightThese objectAtIndex:0];
      // Load Image Here
      // START
      CGRect screenRect = [[UIScreen mainScreen] bounds];
      CGFloat screenWidth = screenRect.size.width;
      PHFetchResult *savedAssets = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObjects:[assetURL stringByReplacingOccurrencesOfString:@"asset-library://" withString:@""], nil] options:nil];
      [savedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        CGFloat resW = asset.pixelWidth;
        CGFloat resH = asset.pixelHeight;
        resH = 300 * retinaScale;
        CGFloat aspectRatio = resH/resW;
        if(isnan(screenWidth*aspectRatio))
          aspectRatio = 1;
        CGFloat desiredHeight = screenWidth*aspectRatio;
        CGSize desiredSize = CGSizeMake(screenWidth, desiredHeight);
        PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
        //            cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
        cropToSquare.synchronous = NO;
        cropToSquare.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager]
         requestImageForAsset:(PHAsset *)asset
         targetSize:desiredSize
         contentMode:PHImageContentModeAspectFit
         options:cropToSquare
         resultHandler:^(UIImage *result, NSDictionary *info) {
           dispatch_async(dispatch_get_main_queue(), ^{
             if([highLightThese count] > 1) {
             }
           });
         }];
      }];
      // END
    }
    else
    {
      [highLightThese removeObject:assetURL];
      if([highLightThese count] > 0)
        assetURL = [highLightThese objectAtIndex:0];
      
      // Load Image Here
      // START
      CGRect screenRect = [[UIScreen mainScreen] bounds];
      CGFloat screenWidth = screenRect.size.width;
      PHFetchResult *savedAssets = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObjects:[assetURL stringByReplacingOccurrencesOfString:@"asset-library://" withString:@""], nil] options:nil];
      [savedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        CGFloat resW = asset.pixelWidth;
        CGFloat resH = asset.pixelHeight;
        resH = 300 * retinaScale;
        CGFloat aspectRatio = resH/resW;
        if(isnan(screenWidth*aspectRatio))
          aspectRatio = 1;
        CGFloat desiredHeight = screenWidth*aspectRatio;
        CGSize desiredSize = CGSizeMake(screenWidth, desiredHeight);
        PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
        //            cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
        cropToSquare.synchronous = NO;
        cropToSquare.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager]
         requestImageForAsset:(PHAsset *)asset
         targetSize:desiredSize
         contentMode:PHImageContentModeAspectFit
         options:cropToSquare
         resultHandler:^(UIImage *result, NSDictionary *info) {
           dispatch_async(dispatch_get_main_queue(), ^{
             if([highLightThese count] > 1) {
             }
           });
         }];
      }];
      // END
    }
    if([highLightThese count] == 0) {
      // distanceFromTop.constant = 65;
      // imageViewHeight.constant = 0;
      // topToCollectionView.constant = 0;
    }
    else if([highLightThese count] > 0) {
      // distanceFromTop.constant = 365;
      // imageViewHeight.constant = 300;
      // topToCollectionView.constant = 300;
    }
    if([highLightThese count]>=1) {
      [nextButton setHidden:NO];
    }
    else {
      [nextButton setHidden:YES];
    }
    [collectionView reloadData];
  }
}

/* Load Photo */

-(void) loadPhoto
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.view showActivityView];
  });
  __block NSUInteger blockCounter = 0;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
    
    
    PHFetchResult *allPhotosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosOptions];
    
    NSUInteger j = 0;
    for(NSUInteger i = lastNumber; i < allPhotosResult.count; i++) {
      j = i;
      PHAsset *result = (PHAsset*)allPhotosResult[i];
      if(showOnlyPhotosWithGPS == YES) {
        if(CLLocationCoordinate2DIsValid(result.location.coordinate)) {
          if(result.location.coordinate.latitude!=0 && result.location.coordinate.longitude!=0) {
            [self.assets addObject:result];
            blockCounter++;
          }
        }
      }
      else {
        [self.assets addObject:result];
        blockCounter++;
      }
      if(blockCounter == LOADATONCE) {
        break;
      }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      lastNumber = j+1;
      // NSLog(@"Last Num = %d %d %d",lastNumber,allPhotosResult.count,self.assets.count);
      if(self.assets.count >= allPhotosResult.count)
        hasReachedEnd = YES;
      
      NSString *loadedSoFar = [NSString stringWithFormat:@"Loaded %d/%d",self.assets.count,totalNumberOfPhotos];
      [howMany setText:loadedSoFar];
      [self.collectionView reloadData];
    });
    //    }];
  });
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.view hideActivityView];
  });
  
}

-(void) addLiveCamera
{
  NSIndexPath *ip = [[NSIndexPath alloc] initWithIndex:0];
  UICollectionViewCell *firstCell = [self.collectionView cellForItemAtIndexPath:ip];
}
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}
-(void) showCamera
{
  NSLog(@"Camera Selected");
}
- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return self.assets.count;
}

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
  static dispatch_once_t pred = 0;
  static ALAssetsLibrary *library = nil;
  dispatch_once(&pred, ^{
    library = [[ALAssetsLibrary alloc] init];
  });
  return library;
}


-(IBAction)donePressed:(id)sender
{
  if([highLightThese count] == 0)
  {
    NSLog(@"Please Select One");
  }
  else
  {
    NSMutableArray *allImagesIPicked = [[NSMutableArray alloc] init];
    for(NSString *ip in highLightThese)
    {
      [allImagesIPicked addObject:ip];
    } // end of for loop
    [self dismissViewControllerAnimated:NO completion:^{
      if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
        [self.delegate imageSelected:allImagesIPicked];
      }
    }];

  }
}
-(IBAction)skipPressed:(id)sender
{
//  self.selectedImage = Nil;
  [self dismissViewControllerAnimated:NO completion:^{
    if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
      [self.delegate imageSelected:Nil];
    }
  }];
}
-(UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize sourceImage:(UIImage*)sourceImage
{
  UIImage *newImage = nil;
  CGSize imageSize = sourceImage.size;
  CGFloat width = imageSize.width;
  CGFloat height = imageSize.height;
  CGFloat targetWidth = targetSize.width;
  CGFloat targetHeight = targetSize.height;
  CGFloat scaleFactor = 0.0;
  CGFloat scaledWidth = targetWidth;
  CGFloat scaledHeight = targetHeight;
  CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
  
  if (CGSizeEqualToSize(imageSize, targetSize) == NO)
  {
    CGFloat widthFactor = targetWidth / width;
    CGFloat heightFactor = targetHeight / height;
    
    if (widthFactor > heightFactor)
    {
      scaleFactor = widthFactor; // scale to fit height
    }
    else
    {
      scaleFactor = heightFactor; // scale to fit width
    }
    
    scaledWidth  = width * scaleFactor;
    scaledHeight = height * scaleFactor;
    
    // center the image
    if (widthFactor > heightFactor)
    {
      thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
    }
    else
    {
      if (widthFactor < heightFactor)
      {
        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
      }
    }
  }
  
  UIGraphicsBeginImageContext(targetSize); // this will crop
  //UIGraphicsBeginImageContextWithOptions(targetSize, 1.0, 0.0);
  
  CGRect thumbnailRect = CGRectZero;
  thumbnailRect.origin = thumbnailPoint;
  thumbnailRect.size.width  = scaledWidth;
  thumbnailRect.size.height = scaledHeight;
  
  [sourceImage drawInRect:thumbnailRect];
  
  newImage = UIGraphicsGetImageFromCurrentImageContext();
  
  if(newImage == nil)
  {
    NSLog(@"could not scale image");
  }
  
  //pop the context to get back to the default
  UIGraphicsEndImageContext();
  
  return newImage;
}

-(IBAction)cancelPressed:(id)sender
{
  [self dismissViewControllerAnimated:NO completion:^{
    if ([self.delegate respondsToSelector:@selector(imageSelectionCancelled)]) {
      [self.delegate imageSelectionCancelled];
    }
  }];
}


- (void) initializeCamera {
  if (session)
    [session release], session=nil;
  CameraCell *firstCell = (CameraCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
  UIImageView *view = [firstCell getImageView];
  session = [[AVCaptureSession alloc] init];
  session.sessionPreset = AVCaptureSessionPresetLow;
  
  if (captureVideoPreviewLayer)
    [captureVideoPreviewLayer release], captureVideoPreviewLayer=nil;
  
  captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
  [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  
  captureVideoPreviewLayer.frame = view.bounds;
  [view.layer addSublayer:captureVideoPreviewLayer];
  
  
  CALayer *viewLayer = [view layer];
  [viewLayer setMasksToBounds:YES];
  
  CGRect bounds = [view bounds];
  [captureVideoPreviewLayer setFrame:bounds];
  
  NSArray *devices = [AVCaptureDevice devices];
  AVCaptureDevice *backCamera=nil;
  
  // check if device available
  if (devices.count==0) {
    NSLog(@"No Camera Available");
    return;
  }
  
  for (AVCaptureDevice *device in devices) {
    
    NSLog(@"Device name: %@", [device localizedName]);
    
    if ([device hasMediaType:AVMediaTypeVideo]) {
      
      if ([device position] == AVCaptureDevicePositionBack) {
        NSLog(@"Device position : back");
        backCamera = device;
      }
    }
  }
  NSError *error = nil;
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
  if (!input) {
    NSLog(@"ERROR: trying to open camera: %@", error);
  }
  else
  {
    [session addInput:input];
    if (stillImageOutput)
      [stillImageOutput release], stillImageOutput=nil;
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil] autorelease];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
    
    [session startRunning];
  }
  
}



/* YCameraView Delegate Start */
-(void)didFinishPickingImage:(UIImage *)image metadata:(NSDictionary *)metadata {
  // Use image as per your need
  [self dismissViewControllerAnimated:NO completion:^{
    [self.view showActivityView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [[CustomeImagePicker defaultAssetsLibrary] writeImageToSavedPhotosAlbum:[image CGImage] metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        NSMutableArray *allImagesIPicked = [[NSMutableArray alloc] init];
        PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
        allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHFetchResult *allPhotosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosOptions];
        if(allPhotosResult.count > 0) {
          PHAsset *asset = [allPhotosResult objectAtIndex:0];
          [allImagesIPicked addObject:[NSString stringWithFormat:@"asset-library://%@",asset.localIdentifier]];
        }
        allPhotosResult = Nil;
        allPhotosOptions = Nil;
        // [allImagesIPicked addObject:assetURL.absoluteString];
        // Now insert the Camera Image at 0 and 2 more
        if([highLightThese count]>=1)
        {
          int count = 1;
          for(NSString *ip in highLightThese)
          {
            [allImagesIPicked addObject:[NSString stringWithFormat:@"asset-library://%@",ip]];
            count++;
            if(count >= maxPhotos)
              break;
          } // end of for loop
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
            [self dismissViewControllerAnimated:NO completion:^{
              [self.delegate imageSelected:allImagesIPicked];
            }];
          }
        });
      }];
    });
  }];
}
/* YCameraView Delegate End */

@end
