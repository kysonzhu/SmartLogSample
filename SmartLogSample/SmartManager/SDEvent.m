//
//  SDEvent.m
//  SocketRobotDemo
//
//  Created by kyson老师 on 2019/1/29.
//  Copyright https://www.kyson.cn All rights reserved.
//

#import "SDEvent.h"
#import <MJExtension/MJExtension.h>




@implementation SDEvent


+(NSDictionary *)mj_replacedKeyFromPropertyName
{
    return @{
             @"eventId":@"id"
             };
}

@end


@implementation SDBody

+(NSDictionary *)mj_objectClassInArray
{
    return @{
             @"events":NSStringFromClass([SDEvent class])
             };
}

@end

