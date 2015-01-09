//
//  ViewController.m
//  CustomImagePicker
//
//  Created by C S P Nanda on 1/5/15.
//  Copyright (c) 2015 C S P Nanda. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize imageView;
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
  [self presentViewController:cip animated:YES completion:^{
    
  }
   ];
}

-(void) imageSelected:(UIImage *)img
{
  imageView.image = img;
}

-(void) imageSelectionCancelled
{
  
}



@end
