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
@synthesize imageView1,imageView2,imageView3;
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
  CustomeImagePicker *cip = [[CustomeImagePicker alloc] init];
  cip.delegate = self;
  [cip setHideSkipButton:NO];
  [cip setHideNextButton:NO];
  [cip setMaxPhotos:MAX_ALLOWED_PICK];
  [cip setShowOnlyPhotosWithGPS:NO];

  [self presentViewController:cip animated:YES completion:^{
  }
   ];
}

-(void) imageSelected:(NSArray *)arrayOfImages
{
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view showActivityView];
    }); // Main Queue to Display the Activity View
    int count = 0;
    for(NSString *imageURLString in arrayOfImages)
    {
      // Asset URLs
      ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
      [assetsLibrary assetForURL:[NSURL URLWithString:imageURLString] resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        CGImageRef imageRef = [representation fullScreenImage];
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        if (imageRef) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if(count==0)
            {
              [imageView1 setImage:image];
            }
            if(count==1)
            {
              [imageView2 setImage:image];
            }
            if(count==2)
            {
              [imageView3 setImage:image];
            }
          });
        } // Valid Image URL
      } failureBlock:^(NSError *error) {
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
