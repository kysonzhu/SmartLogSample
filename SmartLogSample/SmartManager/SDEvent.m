//
//  SDEvent.m
//  SocketRobotDemo
//
//  Created by liyazhou on 2019/1/29.
//  Copyright © 2019 达疆. All rights reserved.
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

