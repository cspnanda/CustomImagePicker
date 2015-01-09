# CustomImagePicker
An integrated Image Picker for iPhone like the one used in FB or twitter.
All the images in your Camera Roll is shown as cells in a collection view.
The Camera is shown as the first cell. Look at the attached screenshot.jpg

How to Use it
-------------
1. Drop the file CustomImagePicker.h,.m,.xib and PhotoCell.h,.m,.xib into your project. Add AssetsLibrary.framework
2. Import CustomImagePicker.h into your ViewController.h and implement the delegate CustomeImagePickerDelegate
3. Implement method -(void) imageSelected:(UIImage *)img in your ViewController to get the image you just clicked
   or chose from Camera Roll.

