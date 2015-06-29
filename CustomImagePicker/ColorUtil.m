//
//  ColorUtil.m
//
//  Created by İlyas Doğruer
//

#import "ColorUtil.h"

@implementation ColorUtil

+(UIColor *)colorFromHexString:(NSString *)hexString withAlpha:(float)alpha {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    
    CGFloat r = ((rgbValue & 0xFF0000) >> 16)/255.0f;
    CGFloat g = ((rgbValue & 0xFF00) >> 8)/255.0f;
    CGFloat b = (rgbValue & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

+(UIColor *)colorFromHexValue:(UInt32)hexValue withAlpha:(float)alpha {
    int redValue = (hexValue >> 16) & 0xFF;
    int greenValue = (hexValue >> 8) & 0xFF;
    int blueValue = (hexValue) & 0xFF;
    
    CGFloat r = redValue / 255.0f;
    CGFloat g = greenValue / 255.0f;
    CGFloat b = blueValue / 255.0f;
        
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

@end
