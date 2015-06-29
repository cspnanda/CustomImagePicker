//
//  ColorUtil.h
//
//  Created by İlyas Doğruer
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Availability.h>

@interface ColorUtil : NSObject

+(UIColor *)colorFromHexString:(NSString *)hexString withAlpha:(float)alpha;
+(UIColor *)colorFromHexValue:(UInt32)hexValue withAlpha:(float)alpha;

@end
