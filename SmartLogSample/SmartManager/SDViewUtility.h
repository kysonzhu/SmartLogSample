//
//  SDViewUtility.h
//  SocketRobotDemo
//
//  Created by kyson老师 on 2019/2/14.
//  Copyright https://www.kyson.cn All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSObject(smartlog2)


-(NSString *) pageId;

-(void) setPageId:(NSString *) pageId;

-(NSString *) eventId;

-(void) setEventId:(NSString *)eventId;


@end


@interface UIControl(smartlog)


@end

@interface NSObject (smartlog)

//是否需要日志
-(NSNumber *) shouldSmartLog;

-(void) setShouldSmartLog:(NSNumber *) shouldSmartLog;

@end


@interface UIView (identifer)

-(NSString *) identifier;

-(void) setIdentifier:(NSString *) identifier;

-(NSString *) viewDepth;

-(void) setViewDepth:(NSString *) viewDepth;


-(NSString *) viewIndex;

-(void) setViewIndex:(NSString *) viewIndex;


// 判断View是否显示在屏幕上
- (BOOL)isDisplayedInScreen;


@end

@interface SDViewUtility : NSObject

+(SDViewUtility *) shareInstance;

- (NSDictionary *)hierarchyDepthsForViews:(NSArray *)views;


- (NSArray *)allViewsInHierarchy;


- (NSArray *)allRecursiveSubviewsInView:(UIView *)view;


+ (NSArray *)allWindows;

@end

NS_ASSUME_NONNULL_END
