//
//  ViewController.h
//  CustomImagePicker
//
//  Created by C S P Nanda on 1/5/15.
//  Copyright (c) 2015 C S P Nanda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomeImagePicker.h"
@interface ViewController : UIViewController <CustomeImagePickerDelegate>
@property(nonatomic, weak) IBOutlet UIImageView *imageView1;
@property(nonatomic, weak) IBOutlet UIImageView *imageView2;
@property(nonatomic, weak) IBOutlet UIImageView *imageView3;

@end
