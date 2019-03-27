//
//  UIImageScaleTool.m
//  Shop
//
//  Created by jiangzhenfeng on 15/3/24.
//  Copyright (c) 2015年 DaDa Inc. All rights reserved.
//

#import "SDUIImageTools.h"

@implementation SDUIImageTools

+ (UIImage *)scaleToSizeWithImage:(UIImage *)image
                          andSize:(CGSize)size
                     isForceScale:(BOOL)force {
  CGFloat width = CGImageGetWidth(image.CGImage);
  CGFloat height = CGImageGetHeight(image.CGImage);
  int xPos = 0;
  int yPos = 0;
  if (force) {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(xPos, yPos, size.width, size.height)];
  } else {
    float verticalRadio = size.height * 1.0 / height;
    float horizontalRadio = size.width * 1.0 / width;
    float radio = 1;
    if (verticalRadio > 1 && horizontalRadio > 1) {
      radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
    } else {
      radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
    }
    width = width * radio;
    height = height * radio;
    xPos = (size.width - width) / 2;
    yPos = (size.height - height) / 2;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(xPos, yPos, width, height)];
  }

  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return scaledImage;
}

+ (UIImage *)scaleToSizeWithImage:(UIImage *)image fillTheSize:(CGSize)size {
  CGFloat width = CGImageGetWidth(image.CGImage);
  CGFloat height = CGImageGetHeight(image.CGImage);
  int xPos = 0;
  int yPos = 0;
  float verticalRadio = size.height * 1.0 / height;
  float horizontalRadio = size.width * 1.0 / width;
  float radio = 1;
  if (verticalRadio > 1 && horizontalRadio > 1) {
    radio = verticalRadio < horizontalRadio ? horizontalRadio : verticalRadio;
  } else {
    radio = verticalRadio > horizontalRadio ? verticalRadio : horizontalRadio;
  }
  if (radio == horizontalRadio) {
    width = width * radio;
    height = height * radio;
    xPos = (size.width - width) / 2;
    yPos = (size.height - height) / 2;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(xPos, yPos, width, height)];

    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
  } else {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(xPos, yPos, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
  }
}

+ (void)scaleTheEnlargementView:(UIImageView *)theImageView
                      withImage:(UIImage *)theImage {
  CGFloat width = 0;
  CGFloat height = 0;
  if (theImage != nil) {
    width = CGImageGetWidth(theImage.CGImage);
    height = CGImageGetHeight(theImage.CGImage);
  } else if (theImageView.image != nil) {
    width = CGImageGetWidth(theImageView.image.CGImage);
    height = CGImageGetHeight(theImageView.image.CGImage);
  }
  CGSize size = theImageView.frame.size;
  float verticalRadio = size.height * 1.0 / height;
  float horizontalRadio = size.width * 1.0 / width;
  float radio = 1;
  if (verticalRadio > 1 && horizontalRadio > 1) {
    radio = verticalRadio < horizontalRadio ? horizontalRadio : verticalRadio;
  } else {
    radio = verticalRadio > horizontalRadio ? verticalRadio : horizontalRadio;
  }
  if (radio == horizontalRadio) {
    theImageView.contentMode = UIViewContentModeScaleAspectFill;
  } else {
    theImageView.contentMode = UIViewContentModeScaleToFill;
  }
  if (theImage != nil) {
    [theImageView setImage:theImage];
  }
}

+ (UIImage *)convertViewToImage:(UIView *)v WithRect:(CGRect)rect {
    CGSize s = rect.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, YES, [UIScreen mainScreen].scale);
    //    UIGraphicsBeginImageContext(s);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


+ (UIImage *)convertViewToImage:(UIView *)v {
  CGSize s = v.bounds.size;
  // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
//    UIGraphicsBeginImageContextWithOptions(s, YES, [UIScreen mainScreen].scale);
    UIGraphicsBeginImageContextWithOptions(s, YES, 1);
  //    UIGraphicsBeginImageContext(s);
  [v.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (UIImage *)convertScrollViewToImage:(UIScrollView *)scrollView
               andScrollViewContainer:(UIView *)container {
  CGSize boundsSize = container.bounds.size;
  CGFloat boundsWidth = container.bounds.size.width;
  CGFloat boundsHeight = container.bounds.size.height;
  CGPoint offset = scrollView.contentOffset;
  [scrollView setContentOffset:CGPointMake(0, 0)];

  CGFloat contentHeight = scrollView.contentSize.height;
  NSMutableArray *images = [NSMutableArray array];
  while (contentHeight > 0) {
    UIGraphicsBeginImageContextWithOptions(boundsSize, YES,
                                           [UIScreen mainScreen].scale);
    [container.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [images addObject:image];

    CGFloat offsetY = scrollView.contentOffset.y;
    [scrollView setContentOffset:CGPointMake(0, offsetY + boundsHeight)];
    contentHeight -= boundsHeight;
  }
  [scrollView setContentOffset:offset];

  UIGraphicsBeginImageContextWithOptions(scrollView.contentSize, YES,
                                         [UIScreen mainScreen].scale);
  [images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
        [image drawInRect:CGRectMake(0, boundsHeight * idx, boundsWidth, boundsHeight)];
      
  }];
  UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return fullImage;
}



@end
