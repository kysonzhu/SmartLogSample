//
//  SDManager.h
//  SocketRobotDemo
//
//  Created by liyazhou on 2019/3/25.
//  Copyright © 2019 达疆. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDManager : NSObject

@property (nonatomic, copy) NSString *uploadURL;//上传的URL
@property (nonatomic, copy) NSString *configURL;//拉取所有埋点的URL


+(SDManager *) shareInstance;

/**
 * 连接到服务器
 */
-(void) connectServer:(NSString *) server;

@end

NS_ASSUME_NONNULL_END
