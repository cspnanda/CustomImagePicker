# CustomImagePicker
An integrated Image Picker for iPhone like the one used in FB or twitter.
All the images in your Camera Roll is shown as cells in a collection view.
The Camera is shown as the first cell. Look at the attached screenshot.jpg.
v2.0 adds the support for live camera feed. Read more about it at http://iosrecipe.blogspot.com/2015/06/integrated-image-picker-for-ios.html

Branches
--------
1. Master branch uses the ALAssetLibrary to handle photos.
2. photokit branch uses the PHAsset or the new Photo framework to handle photos. All new
   functionality will be available by Apple in the photokit going forward.

How to Use it
-------------
1. Add all files from the example project except the AppDelegate and
   ViewController to your project.
2. Import CustomImagePicker.h into your ViewController.h and implement the 
   delegate CustomeImagePickerDelegate
3. Implement method -(void) imageSelected:(NSArray *)arrayOfImages in your 
   ViewController to get the array containing AssetURLs.
