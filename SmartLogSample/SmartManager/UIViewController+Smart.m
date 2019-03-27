//
//  SDViewController+Smart.m
//  shop
//
//  Created by kyson老师 on 2019/2/25.
//  Copyright © 2019 DaDa Inc. All rights reserved.
//

#import "UIViewController+Smart.h"
#import <objc/runtime.h>
#import "SDViewUtility.h"
#import "SDEvent.h"
#import <FMDB/FMDB.h>
#import <MJExtension/MJExtension.h>

@implementation UIViewController(Smart)



+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self sm_swizzleSEL:@selector(viewDidAppear:) withSEL:@selector(sm_swizzled_viewDidAppear:)];
    });
}


- (void)sm_swizzled_viewDidAppear:(BOOL)animated {
    [self sm_swizzled_viewDidAppear:animated];
    
    [self performSelector:@selector(setSmartLogOpts) withObject:nil afterDelay:2];
}

-(void)setSmartLogOpts {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *file = [NSString stringWithFormat:@"%@/smartlog.db",path];
    FMDatabase *db = [FMDatabase databaseWithPath:file];
    
    if (nil != db)
    {
        if (![db open]) {
            NSLog(@"数据库打开失败！");
        } else
        {
            NSString *className = NSStringFromClass(self.class);
            NSString *queryString = [NSString stringWithFormat:@"SELECT * from t_log WHERE pageId = '%@' ;",className];
            FMResultSet * set = [db executeQuery:queryString];
            if ([set next])
            {
                // next 返回yes说明有数据
                NSString *events = [set stringForColumn:@"events"];
                NSData* data=[events dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSArray<NSDictionary *> *eventArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (nil == error && [eventArray isKindOfClass:[NSArray class]])
                {
                    NSArray<SDEvent *> *events = [SDEvent mj_objectArrayWithKeyValuesArray:eventArray];
                    [events enumerateObjectsUsingBlock:^(SDEvent *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSString *identify = obj.widgetIdentifier;
                        //深度为0的第一个，类型为UIWindow；
                        //                        identify = @"0,0@UIWindow;1,0@UIView;2,0@UIButton";
                        
                        NSArray *allViews = [SDViewUtility.shareInstance allViewsInHierarchy];
                        
                        NSDictionary *depthsForViews = [SDViewUtility.shareInstance hierarchyDepthsForViews:allViews];
                        NSArray *everyDepthViewIdentifier = [identify componentsSeparatedByString:@";"];
                        
                        for (NSInteger index = 0; index < everyDepthViewIdentifier.count; ++index)
                        {
                            NSString *currentDepth = everyDepthViewIdentifier[index];
                            //0,0@UIWindow
                            NSArray *everyViewTypes = [currentDepth componentsSeparatedByString:@"@"];
                            //获取UIWindow
                            NSString *currentViewType = everyViewTypes.lastObject;
                            //获取位置
                            NSString *currentViewIdentifier = everyViewTypes.firstObject;
                            //获取,
                            NSArray *everyViewLocation = [currentViewIdentifier componentsSeparatedByString:@","];
                            //获取第一个深度
                            NSString *depthOfView = everyViewLocation.firstObject;
                            NSNumber *depthOfViewNumber = [NSNumber numberWithInteger:depthOfView.integerValue];
                            //获取当前深度下的第几个view
                            NSString *currentIndexOfView = everyViewLocation.lastObject;
                            NSNumber *currentIndexOfViewNumber = [NSNumber numberWithInteger:currentIndexOfView.integerValue];
                            
                            NSInteger accutator = 0;
                            UIView *selectedView = nil;
                            for (NSInteger index2 = 0; index2 < allViews.count; ++ index2)
                            {
                                UIView *view2 = allViews[index2];
                                NSNumber *depth = [depthsForViews objectForKey:[NSValue valueWithNonretainedObject:view2]];
                                if (depth.integerValue == depthOfViewNumber.integerValue)
                                {
                                    
                                    if (currentIndexOfViewNumber.integerValue == accutator)
                                    {
                                        selectedView = view2;
                                        
                                        if ([selectedView isMemberOfClass:NSClassFromString(currentViewType)])
                                        {
                                            allViews = [SDViewUtility.shareInstance allRecursiveSubviewsInView:selectedView];
                                            depthsForViews = [SDViewUtility.shareInstance hierarchyDepthsForViews:allViews];
                                            
                                            if (index == everyDepthViewIdentifier.count - 1) {
                                                NSLog(@"####selectedView==%@",selectedView);
                                                selectedView.shouldSmartLog = @(1);
                                                selectedView.eventId = obj.eventId;
                                                selectedView.pageId = className;
                                            }
                                            
                                            break;
                                        }
                                    }
                                    accutator++;
                                }
                                
                            }
                        }
                        NSLog(@"%@",depthsForViews);
                    }];
                }
                
                NSLog(@"events:%@",events);
            }else{
                NSLog(@"没有找到结果");
            }
        }
    }
}



+ (void)sm_swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSEL);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@end
