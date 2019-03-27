//
//  SDViewUtility.m
//  SocketRobotDemo
//
//  Created by liyazhou on 2019/2/14.
//  Copyright © 2019 达疆. All rights reserved.
//

#import "SDViewUtility.h"
#import <objc/message.h>
//#import "FBTweakShakeWindow.h"
#import "UIWindow+Smart.h"
//#import "STMainViewController.h"
#import <objc/runtime.h>
#import "UIView+Smart.h"


static const char *key = "identifer";
static const char *key_depth = "depth";
static const char *key_index = "index";
static const char *key_smartlog = "smartlog";
static const char *key_pageId = "pageId";
static const char *key_eventId = "eventId";

@implementation UIControl(smartlog)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        [self sm_swizzleSEL:@selector(addTarget:action:forControlEvents:) withSEL:@selector(sm_swizzled_addTarget:action:forControlEvents:)];
        [self sm_swizzleSEL:@selector(sendAction:to:from:forEvent:) withSEL:@selector(swizzled_sendAction:to:from:forEvent:)];
    });
}


//- (void)sm_swizzled_addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
//    [self sm_swizzled_addTarget:target action:action forControlEvents:controlEvents];
//    if (self.shouldSmartLog && controlEvents == UIControlEventTouchUpInside) {
//
//    }
//}

- (BOOL)swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    NSLog(@"-=-=-=-=--=-=-=-");
    return [self swizzled_sendAction:action to:target from:sender forEvent:event];
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


@implementation NSObject (smartlog)

//是否需要日志
-(NSNumber *) shouldSmartLog
{
    return objc_getAssociatedObject(self, key_smartlog);
}

-(void) setShouldSmartLog:(NSNumber *) shouldSmartLog
{
    objc_setAssociatedObject(self, key_smartlog, shouldSmartLog, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



-(NSString *) pageId
{
    return objc_getAssociatedObject(self, key_pageId);
}

-(void) setPageId:(NSString *)pageId
{
    objc_setAssociatedObject(self, key_pageId, pageId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString *) eventId
{
    return objc_getAssociatedObject(self, key_eventId);
}

-(void) setEventId:(NSString *)eventId
{
    objc_setAssociatedObject(self, key_eventId, eventId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UIView (identifer)


-(NSString *) identifier;
{
    return objc_getAssociatedObject(self, key);
}

-(void) setIdentifier:(NSString *) identifier;
{
    objc_setAssociatedObject(self, key, identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


-(NSString *) viewDepth;
{
    return objc_getAssociatedObject(self, key_depth);
}

-(void) setViewDepth:(NSString *) viewDepth;
{
    objc_setAssociatedObject(self, key_depth, viewDepth, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


-(NSString *) viewIndex;
{
    
    return objc_getAssociatedObject(self, key_index);
}

-(void) setViewIndex:(NSString *) viewIndex;
{
    objc_setAssociatedObject(self, key_index, viewIndex, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 判断View是否显示在屏幕上
- (BOOL)isDisplayedInScreen
{
    if (self == nil) {
        return NO;
    }
    
    
    // 转换view对应window的Rect
//    CGRect rect = [self.superview convertRect:self.frame toView:nil];
//    if (CGRectIsEmpty(rect) || CGRectIsNull(rect)) {
//        return NO;
//    }
    
    if (nil == self.window) {
        return NO;
    }
    
    if (self.height < 5 || self.width < 5) {
        return NO;
    }
    
    if ([self isMemberOfClass:UIView.class]) {
        return NO;
    }
    
    if (self.userInteractionEnabled == NO ) {
        return NO;
    }
    
    // 若view 隐藏
    if (self.hidden || self.alpha < 0.1) {
        return FALSE;
    }
    
    // 若没有superview
    if (self.superview == nil) {
        return NO;
    }
    
    if ([self isKindOfClass:[UITableViewCell class]]) {
        return YES;
    }
    
    if (![self isKindOfClass:[UIControl class]]) {
        return NO;
    }
    
    return TRUE;
}



@end

@implementation SDViewUtility

+(SDViewUtility *) shareInstance
{
    static SDViewUtility *utility = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        utility = [[SDViewUtility alloc] init];
    });
    return utility;
}


- (NSDictionary *)hierarchyDepthsForViews:(NSArray *)views
{
    NSMutableDictionary *hierarchyDepths = [NSMutableDictionary dictionary];
    for (UIView *view in views) {
        NSInteger depth = 0;
        UIView *tryView = view;
        while (tryView.superview) {
            tryView = tryView.superview;
            depth++;
        }
        view.viewDepth = [NSString stringWithFormat:@"%li",depth];
        [hierarchyDepths setObject:@(depth) forKey:[NSValue valueWithNonretainedObject:view]];
    }
    return hierarchyDepths;
}

- (NSString *)hierarchyDepthsForView:(UIView *)view
{
    NSInteger depth = 0;
    UIView *tryView = view;
    while (tryView.superview) {
        tryView = tryView.superview;
        depth++;
    }
    return [NSString stringWithFormat:@"%li",depth];
}

- (NSArray *)allViewsInHierarchy
{
    NSMutableArray *allViews = [NSMutableArray array];
    NSArray *windows = [self.class allWindows];
    for (UIWindow *window in windows)
    {
        Class cls = NSClassFromString(@"FBTweakShakeWindow");
        if ([window isMemberOfClass:[UIWindow class]] || [window isMemberOfClass:cls] )
        {
            //设置window
            [allViews addObject:window];
            window.identifier = [NSString stringWithFormat:@"0,0@%@",NSStringFromClass(window.class)];

            UIViewController *vc = [window currentViewController];
            Class cls2 = NSClassFromString(@"STMainViewController");
            if ([vc isMemberOfClass:cls2])
            {
//                vc performSelector:<#(SEL)#> withObject:<#(id)#>
//                BOOL leftShowing = ((cls2 *)vc).leftViewShowing;
                BOOL leftShowing = [vc performSelector:@selector(leftShowing) withObject:nil];
                if (leftShowing) {
//                    vc = ((cls2 *)vc).leftViewController;
                    vc = [vc performSelector:@selector(leftViewController) withObject:nil];
                } else {
//                    vc = ((cls2 *)vc).rootViewController;
                    vc = [vc performSelector:@selector(rootViewController) withObject:nil];
                }
                vc.view.identifier = window.identifier;
            }
            [allViews addObjectsFromArray:[self allRecursiveSubviewsInView:vc.view]];
        }
    }
    return allViews;
}


- (NSArray *)allRecursiveSubviewsInView:(UIView *)view
{
    NSMutableArray *subviews = [NSMutableArray array];
    
    for (UIView *subview in view.subviews)
    {
        subview.viewIndex = [NSString stringWithFormat:@"%li",[view.subviews indexOfObject:subview]];
        subview.viewDepth = [self hierarchyDepthsForView:subview];
        //设置identifier
        NSMutableString *identifier = [NSMutableString stringWithFormat:@"%@",subview.superview.identifier];
        if (identifier.length > 0) {
            [identifier appendFormat:@";%@,%@@%@",subview.viewDepth,subview.viewIndex,NSStringFromClass(subview.class)];
        } else {
            [identifier appendFormat:@"%@,%@@%@",subview.viewDepth,subview.viewIndex,NSStringFromClass(subview.class)];
        }

        subview.identifier = identifier;
        if (![view isKindOfClass:[UIButton class]])
        {
            [subviews addObject:subview];
            [subviews addObjectsFromArray:[self allRecursiveSubviewsInView:subview]];
        }
        
    }
    return subviews;
}



+ (NSArray *)allWindows
{
    BOOL includeInternalWindows = YES;
    BOOL onlyVisibleWindows = NO;
    
    NSArray *allWindowsComponents = @[@"al", @"lWindo", @"wsIncl", @"udingInt", @"ernalWin", @"dows:o", @"nlyVisi", @"bleWin", @"dows:"];
    SEL allWindowsSelector = NSSelectorFromString([allWindowsComponents componentsJoinedByString:@""]);
    
    NSMethodSignature *methodSignature = [[UIWindow class] methodSignatureForSelector:allWindowsSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    invocation.target = [UIWindow class];
    invocation.selector = allWindowsSelector;
    [invocation setArgument:&includeInternalWindows atIndex:2];
    [invocation setArgument:&onlyVisibleWindows atIndex:3];
    [invocation invoke];
    
    __unsafe_unretained NSArray *windows = nil;
    [invocation getReturnValue:&windows];
    return windows;
}




@end
