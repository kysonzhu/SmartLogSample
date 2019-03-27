//
//  SDManager.m
//  SocketRobotDemo
//
//  Created by liyazhou on 2019/3/25.
//  Copyright © 2019 达疆. All rights reserved.
//

#import "SDManager.h"
#import <UIKit/UIKit.h>
#import "SDEvent.h"
#import "SDSnapShot.h"
#import "SDViewUtility.h"
#import <MJExtension/MJExtension.h>
#import "SDUIImageTools.h"
#import <SRWebSocket.h>
#import <AFNetworking/AFNetworking.h>
#import <FMDB/FMDB.h>
#import "UIWindow+Smart.h"

@interface SDManager ()<SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;

@end

@implementation SDManager


+(SDManager *) shareInstance
{
    static dispatch_once_t onceToken;
    static SDManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SDManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //每次启动都会拉取最新配置
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchConfigList) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

-(void) connectServer:(NSString *) server
{
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:server]];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

-(void) fetchConfigList
{
    //    appId=1&sdk=1.0.1"
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"appId"] = @"5";
    params[@"sdk"] = @"1.0.1";
    AFHTTPRequestSerializer *serializer = [[AFHTTPRequestSerializer alloc] init];
    [serializer setValue:@"*/*" forHTTPHeaderField:@"accept"];
    [AFHTTPSessionManager manager].requestSerializer = serializer;
    [[AFHTTPSessionManager manager] GET:@"https://smart-user.imdada.cn/event/config/list" parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"\n####request:https://smart-user.imdada.cn/event/config/list \n####response:%@\n",responseObject);
        NSDictionary *response = (NSDictionary *) responseObject;
        if ([response isKindOfClass:[NSDictionary class]])
        {
            NSArray *bodys = response[@"body"];
            if ([bodys isKindOfClass:[NSArray class]])
            {
                for (NSDictionary *bodyItem in bodys) {
                    [self insertToDataBaseWithBody:bodyItem];
                }
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
    
}


-(void)insertToDataBaseWithBody:(NSDictionary *) body
{
    SDBody *resultBody = [SDBody mj_objectWithKeyValues:body];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *file = [NSString stringWithFormat:@"%@/smartlog.db",path];
    FMDatabase *db = [FMDatabase databaseWithPath:file];
    
    if (nil != db)
    {
        if (![db open]) {
            NSLog(@"数据库打开失败！");
        } else
        {
            BOOL result=[db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_log (id integer PRIMARY KEY AUTOINCREMENT, pageId text NOT NULL, events text NOT NULL);"];
            if (result) {
                NSLog(@"创表或者获取表成功");
            } else {
                NSLog(@"创表或者获取表失败");
            }
            
            NSArray<NSDictionary *> *eventsDict = [SDEvent mj_keyValuesArrayWithObjectArray:resultBody.events];
            NSString *events = [eventsDict mj_JSONString];
            
            NSString *queryString = [NSString stringWithFormat:@"select * from t_log where pageId = '%@' ;",resultBody.pageIdentifier];
            FMResultSet * set = [db executeQuery:queryString];
            if (set.next)
            {
                BOOL updateResult = [db executeUpdate:@"UPDATE t_log SET events = ? WHERE pageId = ?;",events,resultBody.pageIdentifier];
                if (updateResult == YES) {
                    NSLog(@"更新成功");
                } else {
                    NSLog(@"更新失败");
                }
            } else {
                //                NSString *updateString = [NSString stringWithFormat:@"INSERT INTO t_log (pageId, events) VALUES (?, ?) ;",resultBody.pageIdentifier,events];
                BOOL updateResult2 = [db executeUpdate:@"INSERT INTO t_log (pageId, events) VALUES (?, ?) ;",resultBody.pageIdentifier,events];
                if (updateResult2 == YES) {
                    NSLog(@"插入成功");
                } else {
                    NSLog(@"插入失败");
                }
            }
            
            //            BOOL updateResult3 = [db executeUpdate:@"insert or replace into t_log (events) values (?) where pageId = ?;",events,resultBody.pageIdentifier];
            //            if (updateResult3 == YES) {
            //                NSLog(@"更新成功");
            //            } else {
            //                NSLog(@"更新失败");
            //            }
            
        }
        
    }
}

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message
{
    NSLog(@"%@",message);

    NSDictionary *msg = [self.class dictionaryWithJsonString:message];
    if (msg && msg[@"type"])
    {
        NSString *snapshotRequest = msg[@"type"];
        if (snapshotRequest && [snapshotRequest isKindOfClass:[NSString class]] && [snapshotRequest isEqualToString:@"snapshot_request"])
        {
            [self sendData];
        }
    }
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}


- (UIViewController *)topViewController
{
    NSArray *windows = [SDViewUtility allWindows];
    for (UIWindow *window in windows)
    {
        Class cls = NSClassFromString(@"FBTweakShakeWindow");
        if ([window isMemberOfClass:[UIWindow class]] || [window isMemberOfClass:cls] )
        {
            UIViewController *vc = [window currentViewController];
            Class cls2 = NSClassFromString(@"FBTweakShakeWindow");
            if ([vc isMemberOfClass:cls2])
            {
//                BOOL leftShowing = ((STMainViewController *)vc).leftViewShowing;
                BOOL leftShowing = [vc performSelector:@selector(leftViewShowing) withObject:nil];
                if (leftShowing) {
//                    vc = ((STMainViewController *)vc).leftViewController;
                    vc = [vc performSelector:@selector(leftViewController) withObject:nil];
                } else {
//                    vc = ((STMainViewController *)vc).rootViewController;
                    vc = [vc performSelector:@selector(rootViewController) withObject:nil];
                }
                UIViewController *topVC = ((UINavigationController *)vc).topViewController;
                return topVC;
            }
            
        }
    }
    return nil;
}


-(void)sendData
{
    //    NSData *decodedImageData = [[NSData alloc]
    //                                initWithBase64EncodedString:encodedImageStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    //    UIImage *decodedImage = [UIImage imageWithData:decodedImageData];
    //    NSLog(@"%@",decodedImage);
    
    SDSnapShot *snapShot = [[SDSnapShot alloc] init];
    snapShot.type = @"snapshot_response";
    
    SDSnapShotContent *content = [[SDSnapShotContent alloc] init];
    content.identifier = NSStringFromClass(self.topViewController.class);
    content.pageName = NSStringFromClass(self.topViewController.class);
    //前后各加一个\"
    
    NSArray *allViews = [SDViewUtility.shareInstance allViewsInHierarchy];
    
    UIImage *snipImage = [SDUIImageTools convertViewToImage:allViews.firstObject];
    //图片
    NSData *data = UIImageJPEGRepresentation(snipImage, 0.08f);
    NSString *encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    content.screenshot = [NSString stringWithFormat:@"\"%@\"",encodedImageStr];
    
    NSMutableArray *resultViews = [[NSMutableArray alloc] init];
    
    for (NSInteger index = 0; index < allViews.count; ++index)
    {
        UIView *viewItem = allViews[index];
        if ( viewItem.isDisplayedInScreen)
        {
            //如果隐藏就不添加
            SDPageWidgets *widgets = [[SDPageWidgets alloc] init];
            //[viewB convertRect:viewC.frame toView:viewA];
            //该例子中显然viewA是目标，viewC是被操作的对象，那么剩下的viewB自然而然就是源了。结果就是计算viewB上的viewC相对于viewA的frame。
            //具体：https://www.jianshu.com/p/0429d79b8aa9
            CGRect rect = [viewItem.superview convertRect:viewItem.frame toView:nil];
            CGFloat bottom = rect.origin.y + rect.size.height;
            CGFloat right = rect.origin.x + rect.size.width;
            if (rect.origin.x >= 0 && bottom <= CGRectGetHeight(UIScreen.mainScreen.bounds)  && right <= CGRectGetWidth(UIScreen.mainScreen.bounds)) {
                widgets.left = [NSString stringWithFormat:@"%f",rect.origin.x];
                widgets.top = [NSString stringWithFormat:@"%f",rect.origin.y];
                widgets.width = [NSString stringWithFormat:@"%f",rect.size.width];
                widgets.height = [NSString stringWithFormat:@"%f",rect.size.height];
                
                widgets.identifier = viewItem.identifier;
                NSLog(@"=======%@",viewItem.identifier);
                [resultViews addObject:widgets];
            }
            
        }
        
    }
    content.widgets = resultViews;
    
    snapShot.content = content;
    NSString *result = [snapShot mj_JSONString];
    NSLog(@"send success,data:%@...%@",result.length > 250 ? [result substringToIndex:250] : result ,result.length > 500 ? [result substringFromIndex:result.length - 500] : result );
    [self.webSocket send:result];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"a" ofType:@"txt"];
    //    NSError *error;
    //    NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    //    NSData *resultData = [data dataUsingEncoding:NSUTF8StringEncoding];
    //    [self.webSocket send:resultData];
    
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"close reason:%@ %li",reason,code);
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    
}


@end
