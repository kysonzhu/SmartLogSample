//
//  SDSnapShot.h
//  SocketRobotDemo
//
//  Created by kyson老师 on 2019/1/28.
//  Copyright https://www.kyson.cn All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

NS_ASSUME_NONNULL_BEGIN


/**
 
 "type": "snapshot_response",
 "content": {
 "identifier": "com.dada.smartsdk.demo.ui.LoginActivity",
 "pageName": "LoginActivity",
 "screenshot": "",
 "widgets": [
 {
 "identifier": "1,1@android.support.v7.widget.AppCompatAutoCompleteTextView,email",
 "top": 107,
 "left": 16,
 "width": 379,
 "height": 44
 },
 
 
 */

@interface SDPageWidgets : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *top;
@property (nonatomic, strong) NSString *left;
@property (nonatomic, strong) NSString *width;
@property (nonatomic, strong) NSString *height;


@end


@interface SDSnapShotContent : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *pageName;
@property (nonatomic, strong) NSString *screenshot;
@property (nonatomic, strong) NSArray<SDPageWidgets *> *widgets;


@end


@interface SDSnapShot : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) SDSnapShotContent *content;


@end

NS_ASSUME_NONNULL_END
