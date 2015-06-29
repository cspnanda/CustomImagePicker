//
//  PhotoShapViewController.m
//  NoshedItStaging
//
//  Created by yuvraj on 08/01/14.
//  Copyright (c) 2014 limbasiya.nirav@gmail.com. All rights reserved.
//

#import "YCameraViewController.h"
#import "AppDelegate.h"
#import <ImageIO/ImageIO.h>

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@interface YCameraViewController (){
    UIInterfaceOrientation orientationLast, orientationAfterProcess;
    CMMotionManager *motionManager;
}
@end

@implementation YCameraViewController
@synthesize delegate,zoomFactor,currentUserLocation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
    //        self.edgesForExtendedLayout = UIRectEdgeNone;
    //    }
    
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    
	// Do any additional setup after loading the view.
    pickerDidShow = NO;
    
    FrontCamera = NO;
    self.captureImage.hidden = YES;
    
    // Setup UIImagePicker Controller
    imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imgPicker.delegate = self;
    imgPicker.allowsEditing = YES;
    
    croppedImageWithoutOrientation = [[UIImage alloc] init];
    
    initializeCamera = YES;
    photoFromCam = YES;
    self.flashToggleButton.selected=NO;
    // Initialize Motion Manager
    [self initializeMotionManager];
    camFocus = [[CameraFocusSquare alloc] init];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (initializeCamera){
        initializeCamera = NO;
        
        // Initialize camera
        [self initializeCamera];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [session stopRunning];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc
{
    [_imagePreview release];
    [_captureImage release];
    [imgPicker release];
    imgPicker = nil;
  camFocus = Nil;
    if (session)
        [session release], session=nil;
    
    if (captureVideoPreviewLayer)
        [captureVideoPreviewLayer release], captureVideoPreviewLayer=nil;
    
    if (stillImageOutput)
        [stillImageOutput release], stillImageOutput=nil;
}

#pragma mark - CoreMotion Task
- (void)initializeMotionManager{
    motionManager = [[CMMotionManager alloc] init];
    motionManager.accelerometerUpdateInterval = .2;
    motionManager.gyroUpdateInterval = .2;
    
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                            if (!error) {
                                                [self outputAccelertionData:accelerometerData.acceleration];
                                            }
                                            else{
                                                NSLog(@"%@", error);
                                            }
                                        }];
}

#pragma mark - UIAccelerometer callback

- (void)outputAccelertionData:(CMAcceleration)acceleration{
    UIInterfaceOrientation orientationNew;
    
    if (acceleration.x >= 0.75) {
        orientationNew = UIInterfaceOrientationLandscapeLeft;
    }
    else if (acceleration.x <= -0.75) {
        orientationNew = UIInterfaceOrientationLandscapeRight;
    }
    else if (acceleration.y <= -0.75) {
        orientationNew = UIInterfaceOrientationPortrait;
    }
    else if (acceleration.y >= 0.75) {
        orientationNew = UIInterfaceOrientationPortraitUpsideDown;
    }
    else {
        // Consider same as last time
        return;
    }
    
    if (orientationNew == orientationLast)
        return;
    
    //    NSLog(@"Going from %@ to %@!", [[self class] orientationToText:orientationLast], [[self class] orientationToText:orientationNew]);
    
    orientationLast = orientationNew;
}

#ifdef DEBUG
+(NSString*)orientationToText:(const UIInterfaceOrientation)ORIENTATION {
    switch (ORIENTATION) {
        case UIInterfaceOrientationPortrait:
            return @"UIInterfaceOrientationPortrait";
        case UIInterfaceOrientationPortraitUpsideDown:
            return @"UIInterfaceOrientationPortraitUpsideDown";
        case UIInterfaceOrientationLandscapeLeft:
            return @"UIInterfaceOrientationLandscapeLeft";
        case UIInterfaceOrientationLandscapeRight:
            return @"UIInterfaceOrientationLandscapeRight";
    }
    return @"Unknown orientation!";
}
#endif

#pragma mark - Camera Initialization

//AVCaptureSession to show live video feed in view
- (void) initializeCamera {
    if (session)
        [session release], session=nil;
    
    session = [[AVCaptureSession alloc] init];
  // session.sessionPreset = AVCaptureSessionPresetPhoto;
  session.sessionPreset = AVCaptureSessionPreset1280x720;
    if (captureVideoPreviewLayer)
        [captureVideoPreviewLayer release], captureVideoPreviewLayer=nil;
    
	captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
	captureVideoPreviewLayer.frame = self.imagePreview.bounds;
	[self.imagePreview.layer addSublayer:captureVideoPreviewLayer];
	
    UIView *view = [self imagePreview];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [view bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera=nil;
    AVCaptureDevice *backCamera=nil;
    
    // check if device available
    if (devices.count==0) {
        NSLog(@"No Camera Available");
        [self disableCameraDeviceControls];
        return;
    }
    
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
//              if([device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
//              {
//                if([device lockForConfiguration:NULL])
//                {
//                  [device setFocusMode:AVCaptureFocusModeAutoFocus];
//                  [device unlockForConfiguration];
//                }
//              }
            }
        }
    }
    
    if (!FrontCamera) {
        
        if ([backCamera hasFlash]){
            [backCamera lockForConfiguration:nil];
            if (self.flashToggleButton.selected)
                [backCamera setFlashMode:AVCaptureFlashModeOn];
            else
                [backCamera setFlashMode:AVCaptureFlashModeOff];
            [backCamera unlockForConfiguration];
            
            [self.flashToggleButton setEnabled:YES];
        }
        else{
            if ([backCamera isFlashModeSupported:AVCaptureFlashModeOff]) {
                [backCamera lockForConfiguration:nil];
                [backCamera setFlashMode:AVCaptureFlashModeOff];
                [backCamera unlockForConfiguration];
            }
            [self.flashToggleButton setEnabled:NO];
        }
        
        NSError *error = nil;
        input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
      else
      {
        [session addInput:input];
        if (stillImageOutput)
          [stillImageOutput release], stillImageOutput=nil;
        
        stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        [stillImageOutput setHighResolutionStillImageOutputEnabled:YES];
        NSDictionary *outputSettings = [[[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil] autorelease];
        [stillImageOutput setOutputSettings:outputSettings];
        
        [session addOutput:stillImageOutput];
        
        [session startRunning];
      }
    }
    
    if (FrontCamera) {
        [self.flashToggleButton setEnabled:NO];
        NSError *error = nil;
        input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
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
  
  for(UIGestureRecognizer *gesture in [self.imagePreview gestureRecognizers])
  {
    [self.imagePreview removeGestureRecognizer:gesture];
  }
  
  UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
  [tapGR setNumberOfTapsRequired:1];
  [tapGR setNumberOfTouchesRequired:1];
  [tapGR setDelegate:self];
  [self.imagePreview addGestureRecognizer:tapGR];
  
  
  if (camFocus)
  {
    [camFocus removeFromSuperview];
  }
  camFocus = [[CameraFocusSquare alloc]initWithFrame:CGRectMake(self.imagePreview.center.x-40, self.imagePreview.center.y-40, 80, 80)];
  [camFocus setBackgroundColor:[UIColor clearColor]];
  [self.imagePreview addSubview:camFocus];
  [camFocus setNeedsDisplay];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:1.0];
  [camFocus setAlpha:0.0];
  [UIView commitAnimations];

}


-(IBAction)zoomChanged:(UISlider*)sender
{
  AVCaptureDevice *currentDevice = input.device;
  if(sender.value == 0)
  {
    if ([currentDevice lockForConfiguration:Nil]) {
      currentDevice.videoZoomFactor = 1.0;
      [currentDevice unlockForConfiguration];
    }
  }
  else
  {
    if ([currentDevice lockForConfiguration:Nil]) {
      currentDevice.videoZoomFactor = 1.0 + sender.value;
      [currentDevice unlockForConfiguration];
    }
  }
}


-(void)tapToFocus:(UITapGestureRecognizer *)singleTap{
  CGPoint touchPoint = [singleTap locationInView:self.imagePreview];
  CGPoint convertedPoint = [captureVideoPreviewLayer captureDevicePointOfInterestForPoint:touchPoint];
  
  
  
  if (camFocus)
  {
    [camFocus removeFromSuperview];
  }
    camFocus = [[CameraFocusSquare alloc]initWithFrame:CGRectMake(touchPoint.x-40, touchPoint.y-40, 80, 80)];
    [camFocus setBackgroundColor:[UIColor clearColor]];
    [self.imagePreview addSubview:camFocus];
    [camFocus setNeedsDisplay];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.5];
    [camFocus setAlpha:0.0];
    [UIView commitAnimations];
  
  
  AVCaptureDevice *currentDevice = input.device;
  
  
  
  if([currentDevice isFocusPointOfInterestSupported] && [currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
    NSError *error = nil;
    [currentDevice lockForConfiguration:&error];
    if(!error){
      [currentDevice setFocusPointOfInterest:convertedPoint];
      [currentDevice setFocusMode:AVCaptureFocusModeAutoFocus];
      [currentDevice unlockForConfiguration];
      NSLog(@"Changed Focus");
    }
  }
}

- (IBAction)snapImage:(id)sender {
    [self.photoCaptureButton setEnabled:NO];
    
    if (!haveImage) {
        self.captureImage.image = nil; //remove old image from view
        self.captureImage.hidden = NO; //show the captured image view
        self.imagePreview.hidden = YES; //hide the live video feed
        [self capImage];
    }
    else {
        self.captureImage.hidden = YES;
        self.imagePreview.hidden = NO;
        haveImage = NO;
    }
}

- (void) capImage { //method to capture image from AVCaptureSession video feed
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                                imageSampleBuffer,
                                                                                kCMAttachmentMode_ShouldPropagate);
            metadata = (__bridge NSDictionary*)attachments;
          
          
          
          CFMutableDictionaryRef mutable = CFDictionaryCreateMutableCopy(NULL, 0, attachments);
          NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
          NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
          [formatter setTimeZone:timeZone];
          [formatter setDateFormat:@"HH:mm:ss.SS"];
          NSDictionary *gpsDict   = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithFloat:fabs(currentUserLocation.coordinate.latitude)], kCGImagePropertyGPSLatitude
                                     , ((currentUserLocation.coordinate.latitude >= 0) ? @"N" : @"S"), kCGImagePropertyGPSLatitudeRef
                                     , [NSNumber numberWithFloat:fabs(currentUserLocation.coordinate.longitude)], kCGImagePropertyGPSLongitude
                                     , ((currentUserLocation.coordinate.longitude >= 0) ? @"E" : @"W"), kCGImagePropertyGPSLongitudeRef
                                     , [formatter stringFromDate:[currentUserLocation timestamp]], kCGImagePropertyGPSTimeStamp
                                     , [NSNumber numberWithFloat:fabs(currentUserLocation.altitude)], kCGImagePropertyGPSAltitude
                                     ,[NSNumber numberWithFloat:currentUserLocation.horizontalAccuracy],kCGImagePropertyGPSDOP
                                     
                                     , nil];
          
          
          CFDictionarySetValue(mutable, kCGImagePropertyGPSDictionary, (__bridge void *)gpsDict);
          
          CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
          
          CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
          NSMutableData *dest_data = [NSMutableData data];
          CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,NULL);
          if(!destination) {
            NSLog(@"***Could not create image destination ***");
          }
          CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) mutable);
          
          //tell the destination to write the image data and metadata into our data object.
          //It will return false if something goes wrong
          BOOL success = CGImageDestinationFinalize(destination);
          
          if(!success) {
            NSLog(@"***Could not create data from image destination ***");
          }
          
          CFRelease(destination);
          CFRelease(source);
          imageData = NULL;
          metadata = (__bridge NSDictionary*)mutable;

            // [self processImage:[UIImage imageWithData:imageData]];
          [self.captureImage setImage:[UIImage imageWithData:dest_data]];
          
          [self setCapturedImage];

          
//          CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
//                                                                      imageSampleBuffer,
//                                                                      kCMAttachmentMode_ShouldPropagate);
//          NSDictionary *andBack = (__bridge NSDictionary*)attachments;
//          ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//          [library writeImageDataToSavedPhotosAlbum:imageData metadata:andBack completionBlock:^(NSURL *assetURL, NSError *error) {
//            if (error) {
//              [self displayErrorOnMainQueue:error withMessage:@"Save to camera roll failed"];
//            }
//          }];
//          
//          if (attachments)
//            CFRelease(attachments);
//          [library release];
//
//          [self.captureImage setImage:[UIImage imageWithData:imageData]];
//          
//          [self setCapturedImage];
        }
    }];
}

- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  });
}

- (UIImage*)imageWithImage:(UIImage *)sourceImage scaledToWidth:(float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void) processImage:(UIImage *)image { //process captured image, crop, resize and rotate
    haveImage = YES;
    photoFromCam = YES;
    
    // Resize image to 640x640
    // Resize image
//     NSLog(@"Image size %f and %f",image.size.width,image.size.height);
//  
//  
//  CGRect screenRect = [[UIScreen mainScreen] bounds];
//  CGFloat screenWidth = screenRect.size.width;
//  CGFloat screenHeight = screenRect.size.height;

  
  
  
  UIImage *smallImage = [self imageWithImage:image scaledToWidth:720]; //UIGraphicsGetImageFromCurrentImageContext();
  CGRect cropRect = CGRectMake(0, 0, smallImage.size.width, smallImage.size.height);
  CGImageRef imageRef = CGImageCreateWithImageInRect([smallImage CGImage], cropRect);
    croppedImageWithoutOrientation = [[UIImage imageWithCGImage:imageRef] copy];
    
    UIImage *croppedImage = nil;
    orientationAfterProcess = orientationLast;
    switch (orientationLast) {
        case UIInterfaceOrientationPortrait:
            NSLog(@"UIInterfaceOrientationPortrait");
            croppedImage = [UIImage imageWithCGImage:imageRef];
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            NSLog(@"UIInterfaceOrientationPortraitUpsideDown");
            croppedImage = [[[UIImage alloc] initWithCGImage: imageRef
                                                       scale: 1.0
                                                 orientation: UIImageOrientationDown] autorelease];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            NSLog(@"UIInterfaceOrientationLandscapeLeft");
            croppedImage = [[[UIImage alloc] initWithCGImage: imageRef
                                                       scale: 1.0
                                                 orientation: UIImageOrientationRight] autorelease];
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            NSLog(@"UIInterfaceOrientationLandscapeRight");
            croppedImage = [[[UIImage alloc] initWithCGImage: imageRef
                                                       scale: 1.0
                                                 orientation: UIImageOrientationLeft] autorelease];
            break;
            
        default:
            croppedImage = [UIImage imageWithCGImage:imageRef];
            break;
    }
    
    CGImageRelease(imageRef);
    
    [self.captureImage setImage:croppedImage];
    
    [self setCapturedImage];
}

- (void)setCapturedImage{
    // Stop capturing image
    [session stopRunning];
    
    // Hide Top/Bottom controller after taking photo for editing
    [self hideControllers];
}

#pragma mark - Device Availability Controls
- (void)disableCameraDeviceControls{
    self.cameraToggleButton.enabled = NO;
    self.flashToggleButton.enabled = NO;
    self.photoCaptureButton.enabled = NO;
}

//#pragma mark - UIImagePicker Delegate
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
//    if (info) {
//        photoFromCam = NO;
//        
//        UIImage* outputImage = [info objectForKey:UIImagePickerControllerEditedImage];
//        if (outputImage == nil) {
//            outputImage = [info objectForKey:UIImagePickerControllerOriginalImage];
//        }
//        
//        if (outputImage) {
//            self.captureImage.hidden = NO;
//            self.captureImage.image=outputImage;
//            
//            [self dismissViewControllerAnimated:YES completion:nil];
//            
//            // Hide Top/Bottom controller after taking photo for editing
//            [self hideControllers];
//        }
//    }
//}

//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
//    initializeCamera = YES;
//    [picker dismissViewControllerAnimated:YES completion:nil];
//}

#pragma mark - Button clicks
- (IBAction)gridToogle:(UIButton *)sender{
    if (sender.selected) {
        sender.selected = NO;
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.ImgViewGrid.alpha = 1.0f;
        } completion:nil];
    }
    else{
        sender.selected = YES;
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.ImgViewGrid.alpha = 0.0f;
        } completion:nil];
    }
}

-(IBAction)switchToLibrary:(id)sender {
    
    if (session) {
        [session stopRunning];
    }
    
    //    self.captureImage = nil;
    
    //    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    //    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //    imagePickerController.delegate = self;
    //    imagePickerController.allowsEditing = YES;
    [self presentViewController:imgPicker animated:YES completion:NULL];
}

- (IBAction)skipped:(id)sender{
    
    if ([delegate respondsToSelector:@selector(yCameraControllerdidSkipped)]) {
        [delegate yCameraControllerdidSkipped];
    }
    
    // Dismiss self view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction) cancel:(id)sender {
    if ([delegate respondsToSelector:@selector(yCameraControllerDidCancel)]) {
        [delegate yCameraControllerDidCancel];
    }
    
    // Dismiss self view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)donePhotoCapture:(id)sender{
  [session stopRunning];
  [motionManager stopDeviceMotionUpdates];
  imgPicker = Nil;
  session = Nil;
  motionManager = Nil;
  captureVideoPreviewLayer = Nil;
  stillImageOutput = Nil;
    if ([delegate respondsToSelector:@selector(didFinishPickingImage:metadata:)]) {
        [delegate didFinishPickingImage:self.captureImage.image metadata:metadata];
    }
    // Dismiss self view controller
    [self dismissViewControllerAnimated:NO completion:^(void)
     {
       
     }];
}

- (IBAction)retakePhoto:(id)sender{
    [self.photoCaptureButton setEnabled:YES];
    self.captureImage.image = nil;
    self.imagePreview.hidden = NO;
    // Show Camera device controls
    [self showControllers];
    
    haveImage=NO;
    FrontCamera = NO;
//    [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.001];
    [session startRunning];
}

- (IBAction)switchCamera:(UIButton *)sender { //switch cameras front and rear cameras
    // Stop current recording process
    [session stopRunning];
    
    if (sender.selected) {  // Switch to Back camera
        sender.selected = NO;
        FrontCamera = NO;
        [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.001];
    }
    else {                  // Switch to Front camera
        sender.selected = YES;
        FrontCamera = YES;
        [self performSelector:@selector(initializeCamera) withObject:nil afterDelay:0.001];
    }
}

- (IBAction)toogleFlash:(UIButton *)sender{
    if (!FrontCamera) {
        if (sender.selected) { // Set flash off
            [sender setSelected:NO];
            
            NSArray *devices = [AVCaptureDevice devices];
            for (AVCaptureDevice *device in devices) {
                if ([device hasMediaType:AVMediaTypeVideo]) {
                    
                    if ([device position] == AVCaptureDevicePositionBack) {
                        NSLog(@"Device position : back");
                        if ([device hasFlash]){
                            
                            [device lockForConfiguration:nil];
                            [device setFlashMode:AVCaptureFlashModeOff];
                            [device unlockForConfiguration];
                            
                            break;
                        }
                    }
                }
            }
            
        }
        else{                  // Set flash on
            [sender setSelected:YES];
            
            NSArray *devices = [AVCaptureDevice devices];
            for (AVCaptureDevice *device in devices) {
                if ([device hasMediaType:AVMediaTypeVideo]) {
                    
                    if ([device position] == AVCaptureDevicePositionBack) {
                        NSLog(@"Device position : back");
                        if ([device hasFlash]){
                            
                            [device lockForConfiguration:nil];
                            [device setFlashMode:AVCaptureFlashModeOn];
                            [device unlockForConfiguration];
                            
                            break;
                        }
                    }
                }
            }
            
        }
    }
}

#pragma mark - UI Control Helpers
- (void)hideControllers{
    [UIView animateWithDuration:0.2 animations:^{
        //1)animate them out of screen
        self.photoBar.center = CGPointMake(self.photoBar.center.x, self.photoBar.center.y+116.0);
        self.topBar.center = CGPointMake(self.topBar.center.x, self.topBar.center.y-44.0);
        
        //2)actually hide them
        self.photoBar.alpha = 0.0;
        self.topBar.alpha = 0.0;
        
    } completion:nil];
}

- (void)showControllers{
    [UIView animateWithDuration:0.2 animations:^{
        //1)animate them into screen
        self.photoBar.center = CGPointMake(self.photoBar.center.x, self.photoBar.center.y-116.0);
        self.topBar.center = CGPointMake(self.topBar.center.x, self.topBar.center.y+44.0);
        
        //2)actually show them
        self.photoBar.alpha = 1.0;
        self.topBar.alpha = 1.0;
        
    } completion:nil];
}

@end
