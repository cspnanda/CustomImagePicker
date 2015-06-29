//
//  CustomeImagePicker.m
//  CustomImagePicker
//
//  Created by Prasanna Nanda on 1/5/15.
//  Copyright (c) 2015 Prasanna Nanda. All rights reserved.
//

#import "CustomeImagePicker.h"
#import "UIView+RNActivityView.h"
@interface CustomeImagePicker ()
@property(nonatomic, strong) NSArray *assets;
// @property(nonatomic,strong) UIImage *selectedImage;
@end

@implementation CustomeImagePicker
@synthesize whereamI,skipButton,nextButton,hideNextButton,hideSkipButton,highLightThese,maxPhotos,distanceFromButton,nearByCollectionView,currentUserLocation,showOnlyPhotosWithGPS;
// @synthesize selectedImages,disselectedImages;

-(BOOL) checkForCamera
{
  AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if(authStatus == AVAuthorizationStatusAuthorized) {
    // do your logic
    return YES;
  }
  return NO;
}
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
//  if(showOnlyPhotosWithGPS==NO && [self checkForCamera] == YES)
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
//  selectedImages = [[NSMutableArray alloc] init];
//  disselectedImages = [[NSMutableArray alloc] init];
  [self.collectionView registerClass:[PhotoPickerCell class] forCellWithReuseIdentifier:@"PhotoPickerCell"];
  [self.collectionView registerClass:[CameraCell class] forCellWithReuseIdentifier:@"CameraCell"];
  
  UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
  if(IS_IPHONE_6 || IS_IPHONE_6P)
    [flowLayout setItemSize:CGSizeMake(120, 120)];
  else
    [flowLayout setItemSize:CGSizeMake(100, 100)];
  [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
  [self.collectionView setCollectionViewLayout:flowLayout];
  
  _assets = [@[] mutableCopy];
  __block NSMutableArray *tmpAssets = [@[] mutableCopy];
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    ALAsset *asset = [[ALAsset alloc] init];
    if(showOnlyPhotosWithGPS==NO)
      [tmpAssets insertObject:asset atIndex:0];
  }
  ALAssetsLibrary *assetsLibrary = [CustomeImagePicker defaultAssetsLibrary];
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if(result)
      {
        if(showOnlyPhotosWithGPS == YES)
        {
          if([result valueForProperty:ALAssetPropertyLocation])
            [tmpAssets addObject:result];
        }
        else
          [tmpAssets addObject:result];
      }
    }
     ];
    
  } failureBlock:^(NSError *error) {
    NSLog(@"Error loading images %@", error);
    if([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized)
    {
      [self displayErrorOnMainQueue:@"Photo Access Disabled" message:@"Please allow Photo Access in System Settings"];
    }
  }];
  self.assets = tmpAssets;
  dispatch_time_t popTime1 = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
  dispatch_after(popTime1, dispatch_get_main_queue(), ^(void){
    if(showOnlyPhotosWithGPS==YES) {
    OLGhostAlertView *ghastly = [[OLGhostAlertView alloc] initWithTitle:@"Photos with Location" message: @"Only Photos with Location Information are shown here." timeout:2.0 dismissible:YES];
    [ghastly show];
    }

    [self.collectionView reloadData];
  });

  // });
  nextButton.layer.borderColor = [[UIColor whiteColor] CGColor];
  nextButton.layer.borderWidth = 1.0f;
  nextButton.layer.cornerRadius = 5.0f;

  skipButton.layer.borderColor = [[UIColor whiteColor] CGColor];
  skipButton.layer.borderWidth = 1.0f;
  skipButton.layer.cornerRadius = 5.0f;
  
//  dispatch_time_t popTime1 = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
//  dispatch_after(popTime1, dispatch_get_main_queue(), ^(void){
//    [self addLiveCamera];
//  });
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

-(void) populateNearbyPhotos {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
  ALAssetsLibrary *assetsLibrary = [CustomeImagePicker defaultAssetsLibrary];
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if(result)
      {
        NSDictionary *metadata = [[result defaultRepresentation] metadata];
        NSMutableDictionary *GPSDictionary = [metadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
        if(GPSDictionary)
        {
          
          CLLocation *locFromPhoto = [[CLLocation alloc] initWithLatitude:[[GPSDictionary objectForKey:@"Latitude"] doubleValue] longitude:[[GPSDictionary objectForKey:@"Longitude"] doubleValue]];
          
          
          CLLocationCoordinate2D loc = CLLocationCoordinate2DMake([[[whereamI objectForKey:@"location"] objectForKey:@"latitude"] doubleValue], [[[whereamI objectForKey:@"location"] objectForKey:@"longitude"] doubleValue]);
          CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude];

          
          CLLocationDistance distance = [locFromPhoto distanceFromLocation:userLocation];
          NSLog(@"%f",distance);
          if(distance < 1000)
          {
            NSLog(@"Nearby");
          }

        }
      }
    }
     ];
    
  } failureBlock:^(NSError *error) {
  }];
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
  static NSString *cellIdentifier = @"PhotoPickerCell";
  static NSString *cameraCellIdentifier = @"CameraCell";
  
  if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
  {
    if(indexPath.row == 0 && indexPath.section == 0 && showOnlyPhotosWithGPS == NO)
    {
      CameraCell *cell = (CameraCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cameraCellIdentifier forIndexPath:indexPath];
      ALAsset *asset = self.assets[indexPath.row];
      ALAssetRepresentation *rep = [asset defaultRepresentation];
      NSString *assetURL = [[rep url] absoluteString];
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
    else
    {
      PhotoPickerCell *cell = (PhotoPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
      
      ALAsset *asset = self.assets[indexPath.row];
      ALAssetRepresentation *rep = [asset defaultRepresentation];
      NSString *assetURL = [[rep url] absoluteString];
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
  } // Device with Camera
  else
  {
    PhotoPickerCell *cell = (PhotoPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = self.assets[indexPath.row];
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    NSString *assetURL = [[rep url] absoluteString];
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
  } //  Device Without Camera
  return Nil;
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

-(void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
  ALAsset *asset = self.assets[indexPath.row];
  ALAssetRepresentation *rep = [asset defaultRepresentation];
  NSString *assetURL = [[rep url] absoluteString];

  if([highLightThese containsObject:assetURL])
  {
    [highLightThese removeObject:assetURL];
//    if(![disselectedImages containsObject:indexPath])
//      [disselectedImages addObject:indexPath];
//    [collectionView reloadItemsAtIndexPaths:selectedImages];
//    [collectionView reloadItemsAtIndexPaths:disselectedImages];
    [collectionView reloadData];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

  if(indexPath.row == 0 && indexPath.section == 0 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && showOnlyPhotosWithGPS == NO)
  {
    if([self checkForCamera] == YES)
    {
      YCameraViewController *ycv = [[YCameraViewController alloc] init];
      [ycv setDelegate:self];
      [ycv setCurrentUserLocation:currentUserLocation];
      [self presentViewController:ycv animated:YES completion:^{
      }];
   }
    else
    {
      [self displayErrorOnMainQueue:@"Camera Access Disabled" message:@"Please allow Camera Access in System Settings"];
    }

  }
  else
  {
    ALAsset *asset = self.assets[indexPath.row];
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    NSString *assetURL = [[rep url] absoluteString];
    
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
//- (UIImage *)fixrotation:(UIImage *)image{
//  
//  
//  if (image.imageOrientation == UIImageOrientationUp) return image;
//  CGAffineTransform transform = CGAffineTransformIdentity;
//  
//  switch (image.imageOrientation) {
//    case UIImageOrientationDown:
//    case UIImageOrientationDownMirrored:
//      transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
//      transform = CGAffineTransformRotate(transform, M_PI);
//      break;
//      
//    case UIImageOrientationLeft:
//    case UIImageOrientationLeftMirrored:
//      transform = CGAffineTransformTranslate(transform, image.size.width, 0);
//      transform = CGAffineTransformRotate(transform, M_PI_2);
//      break;
//      
//    case UIImageOrientationRight:
//    case UIImageOrientationRightMirrored:
//      transform = CGAffineTransformTranslate(transform, 0, image.size.height);
//      transform = CGAffineTransformRotate(transform, -M_PI_2);
//      break;
//    case UIImageOrientationUp:
//    case UIImageOrientationUpMirrored:
//      break;
//  }
//  
//  switch (image.imageOrientation) {
//    case UIImageOrientationUpMirrored:
//    case UIImageOrientationDownMirrored:
//      transform = CGAffineTransformTranslate(transform, image.size.width, 0);
//      transform = CGAffineTransformScale(transform, -1, 1);
//      break;
//      
//    case UIImageOrientationLeftMirrored:
//    case UIImageOrientationRightMirrored:
//      transform = CGAffineTransformTranslate(transform, image.size.height, 0);
//      transform = CGAffineTransformScale(transform, -1, 1);
//      break;
//    case UIImageOrientationUp:
//    case UIImageOrientationDown:
//    case UIImageOrientationLeft:
//    case UIImageOrientationRight:
//      break;
//  }
//  
//  // Now we draw the underlying CGImage into a new context, applying the transform
//  // calculated above.
//  CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
//                                           CGImageGetBitsPerComponent(image.CGImage), 0,
//                                           CGImageGetColorSpace(image.CGImage),
//                                           CGImageGetBitmapInfo(image.CGImage));
//  CGContextConcatCTM(ctx, transform);
//  switch (image.imageOrientation) {
//    case UIImageOrientationLeft:
//    case UIImageOrientationLeftMirrored:
//    case UIImageOrientationRight:
//    case UIImageOrientationRightMirrored:
//      // Grr...
//      CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
//      break;
//      
//    default:
//      CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
//      break;
//  }
//  
//  // And now we just create a new UIImage from the drawing context
//  CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
//  UIImage *img = [UIImage imageWithCGImage:cgimg];
//  CGContextRelease(ctx);
//  CGImageRelease(cgimg);
//  return img;
//  
//}

-(IBAction)cancelPressed:(id)sender
{
//  self.selectedImage = Nil;
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


-(void) doSomeThingWithImage:(NSDictionary*)params
{
  UIImage *image = [params objectForKey:@"data"];
  NSDictionary *metadata = [params objectForKey:@"metadata"];
  params = Nil;
  ALAssetsLibrary *assetsLibrary = [CustomeImagePicker defaultAssetsLibrary];
  [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage
                                     metadata:metadata
                              completionBlock:^(NSURL *assetURL, NSError *error) {
                                [self dismissViewControllerAnimated:NO completion:^{
                                  NSMutableArray *allImagesIPicked = [[NSMutableArray alloc] init];
                                  [allImagesIPicked addObject:assetURL.absoluteString];
                                  // Now insert the Camera Image at 0 and 2 more
                                  if([highLightThese count]>=1)
                                  {
                                    int count = 1;
                                    for(NSString *ip in highLightThese)
                                    {
                                      [allImagesIPicked addObject:ip];
                                      count++;
                                      if(count >= maxPhotos)
                                        break;
                                    } // end of for loop
                                  }
                                  if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
                                    [self.delegate imageSelected:allImagesIPicked];
                                  }
                                }];
                                
                                
                                
                              }];
}



/* YCameraView Delegate Start */
-(void)didFinishPickingImage:(UIImage *)image metadata:(NSDictionary *)metadata {
  // Use image as per your need
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view showActivityView];
    });
    
    
    NSDictionary *extraParams = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:image,metadata,nil] forKeys:[NSArray arrayWithObjects:@"data",@"metadata",nil]];
    
    [NSThread detachNewThreadSelector:@selector(doSomeThingWithImage:) toTarget:self withObject:extraParams];
    
  });
  
}
/* YCameraView Delegate End */


@end
