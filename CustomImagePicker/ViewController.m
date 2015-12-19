//
//  ViewController.m
//  CustomImagePicker
//
//  Created by C S P Nanda on 1/5/15.
//  Copyright (c) 2015 C S P Nanda. All rights reserved.
//

#import "ViewController.h"
#import "UIView+RNActivityView.h"
@interface ViewController ()

@end

@implementation ViewController
@synthesize imageView1,imageView2,imageView3,selectedNow;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)getPhoto:(id)sender
{
  if(!selectedNow)
    selectedNow = [[NSMutableArray alloc] init];
  CustomeImagePicker *cip = [[CustomeImagePicker alloc] init];
  cip.delegate = self;
  [cip setHideSkipButton:NO];
  [cip setHideNextButton:NO];
  [cip setMaxPhotos:MAX_ALLOWED_PICK];
  [cip setShowOnlyPhotosWithGPS:NO];
  [cip setHighLightThese:selectedNow];
  [self presentViewController:cip animated:YES completion:^{
  }
   ];
}
-(void) imageSelected:(NSArray *)arrayOfImages
{
  selectedNow = [arrayOfImages mutableCopy];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view showActivityView];
      [imageView1 setImage:Nil];
      [imageView2 setImage:Nil];
      [imageView3 setImage:Nil];
    }); // Main Queue to Display the Activity View
    int count = 0;
    for(NSString *imageURLString in arrayOfImages)
    {
      // Asset URLs
      PHFetchResult *savedAssets = [PHAsset fetchAssetsWithLocalIdentifiers:[NSArray arrayWithObjects:[imageURLString stringByReplacingOccurrencesOfString:@"asset-library://" withString:@""], nil] options:nil];
      [savedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
        //            cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
        cropToSquare.synchronous = NO;
        cropToSquare.networkAccessAllowed = YES;
        CGFloat resW = asset.pixelWidth;
        CGFloat resH = asset.pixelHeight;

        [[PHImageManager defaultManager]
         requestImageForAsset:(PHAsset *)asset
         targetSize:CGSizeMake(resW, resH)
         contentMode:PHImageContentModeAspectFit
         options:cropToSquare
         resultHandler:^(UIImage *result, NSDictionary *info) {
           dispatch_async(dispatch_get_main_queue(), ^{
             if(count==0)
             {
               [imageView1 setImage:result];
             }
             if(count==1)
             {
               [imageView2 setImage:result];
             }
             if(count==2)
             {
               [imageView3 setImage:result];
             }
           });
         }];

      }];
      count++;
    } // All Images I got
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view hideActivityView];
    });
  }); // Queue for reloading all images
}
-(void) imageSelectionCancelled
{
  
}



@end
