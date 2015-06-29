//
//  CustomeImagePicker.h
//  CustomImagePicker
//
//  Created by Prasanna Nanda on 1/5/15.
//  Copyright (c) 2015 Prasanna Nanda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoPickerCell.h"
#import "CameraCell.h"
#import "Header.h"
#import "OLGhostAlertView.h"
#import "YCameraViewController.h"
#import <ImageIO/ImageIO.h>
#import <MapKit/MapKit.h>

@protocol CustomeImagePickerDelegate <NSObject>

-(void)imageSelected:(NSArray*)arrayOfImages;
-(void)imageSelectionCancelled;

@end



@interface CustomeImagePicker : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate, UINavigationControllerDelegate,YCameraViewControllerDelegate>
{
  AVCaptureSession *session;
  AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
  AVCaptureStillImageOutput *stillImageOutput;
  UIImage *croppedImageWithoutOrientation;

}

@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) IBOutlet UICollectionView *nearByCollectionView;

@property(nonatomic, weak) IBOutlet UIButton *skipButton;
@property(nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) NSIndexPath *selectedItemIndexPath;
@property (nonatomic, assign) NSInteger maxPhotos;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *distanceFromButton;

@property (nonatomic, strong) NSDictionary *whereamI;
//@property (nonatomic, strong) NSMutableArray *selectedImages;
//@property (nonatomic, strong) NSMutableArray *disselectedImages;
@property (nonatomic, assign) BOOL hideSkipButton;
@property (nonatomic, assign) BOOL hideNextButton;
@property (nonatomic, strong) NSMutableArray *highLightThese;
@property(nonatomic,weak) id<CustomeImagePickerDelegate> delegate;
// @property(nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic,strong) CLLocation *currentUserLocation;
@property (nonatomic,assign) BOOL showOnlyPhotosWithGPS;







@end
