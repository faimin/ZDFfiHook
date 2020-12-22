# ZDFfiHook

使用`libffi`实现`hook Objective-C`

[libffi 基本用法](https://github.com/faimin/ZDLibffiDemo)

## 用法

> 1. 不支持`hook`已经被`kvo`过的`属性`，会挂掉，应该是`kvo`内部有什么特殊处理；不过可以先`hook`再执行`kvo`
> 
> 2. 回调的`callback`参数列表与实际被`hook`的参数（不包括`self`、`selector`）一一对应，不带参数的方法 `callback`参数列表为`void`



##### API：

```objectivec
/// hook 实例方法
+ (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

/// hook类方法
+ (ZDFfiHookInfo *)zd_hookClassMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

/// 仅仅对单个实例对象进行hook
- (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

/// 移除hook
+ (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token;

/// 一般情况下不用手动移除单个实例的hook，当实例释放时会自动移除
- (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token;
```

##### 例子

```objective-c
- (void)testFfiHook {
    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:) option:ZDHookOption_After callback:^(NSInteger a, NSString *b, id c){
        NSLog(@"~~~~~后hook");
    }];

    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:) option:ZDHookOption_Befor callback:^(NSInteger a, NSString *b, id c){
        NSLog(@"~~~~~~先hook");
    }];

    id v = [self exeA:100 b:@"啦啦啦" c:NSObject.new];
    NSLog(@"***************** %@", v);
}

#pragma mark - Method

- (id)exeA:(NSInteger)a b:(NSString *)b c:(id)c {
    NSString *ret = [NSString stringWithFormat:@"结果 = %zd， %@， %@", a, b, c];
    return ret;
}
```



## 安装

```ruby
pod 'ZDFfiHook', :git => 'https://github.com/faimin/ZDFfiHook.git'
```
