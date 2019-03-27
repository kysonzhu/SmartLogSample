iOS实现
## 集成
目前可视化埋点已经封装成一个库 SmartLog，使用过程如下：
```
[[SDManager shareInstance] connectServer:HOST_SERVER];
[SDManager shareInstance].configURL = URL_CONFIG;
[[SDManager shareInstance] setUploadURL:URL_UPLOAD];
```
将以上的几个URL替换成相应的URL即可集成。

## 流程
![流程图](http://images.kyson.cn/smartlog/smartlog_06.png)
### 拉取配置
App 启动后会拉取 configList ：
```
https://服务器Host/event/config/list
```
返回的数据格式为：
```
{
	"code": 0,
	"body": [{
		"pageIdentifier": "STFHomeViewController",
		"events": [{
			"id": 254,
			"typeId": 1,
			"widgetIdentifier": "0,0@FBTweakShakeWindow;3,0@UINavigationTransitionView;4,0@UIViewControllerWrapperView;5,0@UIView;6,1@UIView;7,0@STFBenchPanelView;8,0@UIView;9,0@UIButton",
			"expressions": ""
		}, {
			"id": 255,
			"typeId": 1,
			"widgetIdentifier": "0,0@FBTweakShakeWindow;3,0@UINavigationTransitionView;4,0@UIViewControllerWrapperView;5,0@UIView;6,1@UIView;7,0@STFBenchPanelView;8,1@UIView;9,0@UIButton",
			"expressions": ""
		}]
	}],
	"msg": "ok"
}
```
对应到本地的 Model 是 SDBody：
```
@interface SDEvent : NSObject

@property(nonatomic,copy) NSString *expressions;
@property(nonatomic,copy) NSString *eventId;
@property(nonatomic,copy) NSString *typeId;
@property(nonatomic,copy) NSString *widgetIdentifier;

@end


@interface SDBody : NSObject

@property(nonatomic,copy) NSString *pageIdentifier;
@property(nonatomic,copy) NSArray<SDEvent *> *events;

@end
```
将以上数据存入数据库 smartlog 备用，数据库表 t_log 的结构如下：

|字段| id | PageId | events |
|----| ------ | ------ | ------ |
|是否主键| 是 | 否 | 否 |
|类型| int | TEXT | TEXT |

其中 event 是的数据是 json。

### 埋点流程
经过以下几步：
1. 对 viewDidLoad 进行hook操作，方式就是大家熟悉的 AOP。
2. 从数据库拉取当前页面的埋单事件（events）。
3. 对 events 进行解析。
4. 解析并找到指定的控件
5. 设置相应属性，方式也是大家熟悉的关联对象。

其中前两步比较简单，不多做介绍了，第三步说一下：
解析的字符串就是我们从服务端拉下来的 json，比如
```
0,0@FBTweakShakeWindow;3,0@UINavigationTransitionView;4,0@UIViewControllerWrapperView;5,0@UIView;6,1@UIView;7,0@STFBenchPanelView;8,0@UIView;9,0@UIButton
```
稍加分析可以看出，这是根据目录树来定位控件的，画个图示意一下：
![流程图](http://images.kyson.cn/smartlog/smartlog_07.jpg)
UIWindow 是第 0 层，第 0 个；
ControllerA 是第 1 层，第 0 个；
ButtonA 是第 2 层，第 0 个；
ButtonB 是第 2 层，第 1 个；
因此，ButtonA 的定位标识就是：
```
0,0@UIWindow;1,0@UIViewController;2,0@UIButton
```
ButtonB 的定位标识为：
```
0,0@UIWindow;1,0@UIViewController;2,1@UIButton
```

### 触发埋点、上报
对 iOS 事件响应链熟悉的朋友都知道，当 iOS 任何点击事件触发时，会调用方法：
```
sendAction:to:from:forEvent:
```
因此我们只需要 hook 该事件即可：
```
[self sm_swizzleSEL:@selector(sendAction:to:from:forEvent:) withSEL:@selector(swizzled_sendAction:to:from:forEvent:)];
```

## 其他
以上基本涵盖了可视化埋点的所有流程，还有一些补充流程这里也一并说一下：
### 截图上传
可视化埋点的核心在于“可视化”，因此上传本地截图必不可少，由于 H5 端 索取截图的时间未知，因此需要一个长连接机制随时准备服务端的“索图”请求。这里我们使用的是 Facebook 的长连接库：SocketRocket。
关于 SocketRocket 的使用这里不赘述，笔者这里说一下
-  request 格式：
```
ws://服务器Host/wc/type类型/设备类型/设备id/设备型号
```
这样后端可以根据请求类型轻松获取当前机器的一些信息

- 约定token
目前，接受的token有如下：

|token 名| 含义 |
|----| ------ |
|snapshot_request| 截图请求 |

当接受到截图请求后，本地会将当前页面的截图以及控件的位置一并上传。
### 压缩
使用 CoreGraphics 可以轻松将当前页面进行截图，但截取的图片较大，需要进行压缩，通过方法
```
UIImageJPEGRepresentation
```
即可，一个笔者的建议压缩比为0.08，压缩的图片通过 base64 转成图片上传即可。
### 过滤
上传控件树，和之前提到的方式是一样的，通过字符串唯一定位一个控件即可。但如果所有的图片都上传的话，会造成控件显示凌乱的问题，所以需要过滤一下，以下是笔者的一些规则：
- 长宽小于 5 的，不展示
- 当前视图类型是个 UIView，不展示
- userInteractionEnabled 为 No，不展示
- View 当前隐藏，不展示
- View 的边界超出 UIWindow，不展示
- 其他情况

### 上传

最后上传的数据格式如下：
```
格式化JSON：
{
    "type": "snapshot_response", 
    "content": {
        "screenshot": "\"/9j/4AAQSkZJRgABAQAASABIAAD/4QBYRXhpZgAATU0AKgAAAAgBAI2C
levT+dKYyEwOvP61NRQBEU5JxngUiphNpXnipqKAIPLIwOvOfap6KKACiiigD//Z\"", 
        "identifier": "STFHomeViewController", 
        "widgets": [
            {
                "height": "30.000000", 
                "top": "27.000000", 
                "identifier": "0,0@FBTweakShakeWindow;3,1@UINavigationBar;4,2@_UINavigationBarContentView;5,2@_UITAMICAdaptorView;6,0@UIButton", 
                "left": "150.666667", 
                "width": "113.000000"
            }
        ], 
        "pageName": "STFHomeViewController"
    }
}
```

## 总结
本文给出了 iOS中实现可视化埋点的一个大致思路，但其实很多的细节都可以再进行优化，这里算是抛砖引玉，希望对大家有所帮助。


