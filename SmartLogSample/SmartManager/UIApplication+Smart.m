//
//  UIApplication.m
//  shop
//
//  Created by liyazhou on 2019/3/19.
//  Copyright © 2019 DaDa Inc. All rights reserved.
//

#import "UIApplication+Smart.h"

#import <objc/runtime.h>

#import "SDViewUtility.h"
#import <MJExtension/MJExtension.h>
#import <AFNetworking/AFNetworking.h>

@implementation UIApplication (smart)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self sm_swizzleSEL:@selector(sendAction:to:from:forEvent:) withSEL:@selector(swizzled_sendAction:to:from:forEvent:)];
    });
}

- (BOOL)swizzled_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btn = sender;
        if (btn.shouldSmartLog.boolValue == YES) {
            [self startSendLog:sender];
        }
    }
    return [self swizzled_sendAction:action to:target from:sender forEvent:event];
}

-(void)startSendLog:(NSObject *)sender
{
    //    appId=1&sdk=1.0.1"
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"appId"] = @(5);
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    params[@"appVersion"] = version;
    params[@"deviceId"] = [[NSUUID UUID] UUIDString];
    params[@"city"] = @(1);
    params[@"extra"] = [@{@"id":@"1"} mj_JSONString];

    NSMutableDictionary *eventParams = [[NSMutableDictionary alloc] init];
    //1.展示事件2.控件展示事件（因为这是按钮，所以，直接写死1）
    eventParams[@"typeId"] = @(1);
    eventParams[@"id"] = sender.eventId;
    eventParams[@"createTime"] = @([self getNowTimeTimestamp].integerValue);
    eventParams[@"refPageIdentifier"] = ((UIButton *)sender).pageId;
    eventParams[@"extra"] = [@{@"id":@"-1"} mj_JSONString];

    params[@"events"] = @[eventParams];
    
    AFHTTPRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    manager.requestSerializer = serializer;

    [manager POST:@"https://smart-user.imdada.cn/event/log/upload" parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"\n####https://smart-user.imdada.cn/event/log/upload \n####response:%@\n",responseObject);


    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"\n####https://smart-user.imdada.cn/event/log/upload \n####error:%@\n",error);
    }];
}


-(NSString *)getNowTimeTimestamp{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    
    //设置时区,这个对于时间的处理有时很重要
    
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    
    [formatter setTimeZone:timeZone];
    
    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
    
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    
    return timeSp;
    
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


