//
//  SDUIImageTools.h
//  Shop
//
//  Created by jiangzhenfeng on 15/3/24.
//  Copyright (c) 2015年 DaDa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SDUIImageTools : NSObject

+ (UIImage *)scaleToSizeWithImage:(UIImage *)image andSize:(CGSize)size isForceScale:(BOOL)force; // force  是否等比例缩放  把图片缩放
+ (void)scaleTheEnlargementView:(UIImageView *)theImageView withImage:(UIImage *)theImage;
+ (UIImage *)convertViewToImage:(UIView *)v;
+ (UIImage *)convertViewToImage:(UIView *)v WithRect:(CGRect)rect;
+ (UIImage *)convertScrollViewToImage:(UIScrollView *)scrollView andScrollViewContainer:(UIView *)container;

@end
