# ZDFfiHook

使用`libffi`实现`hook Objective-C`


## 原理：

`libffi`根据`Method`动态生成一个新的`NewIMP`，接着`libffi`把这个`NewIMP`与一个`C`函数做关联，然后通过`OC`的方法交换（这里需要保存原始的`IMP`）把`Method`的`IMP`替换为`libffi`生成的`NewIMP`，这样当`OC`方法执行时会走到关联的`C`函数中，在这里我们可以控制原`OC`方法的执行时机来达到`hook`的目的。


## 用法
 
> 回调的`callback`参数列表与实际被`hook`的参数（不包括`self`、`selector`）一一对应，不带参数的方法 `callback`参数列表为`void`



API：

```objc
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

例子

```objc
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

## 参考

- [libffi 基本用法](https://github.com/faimin/ZDLibffiDemo)

