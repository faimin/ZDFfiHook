# ZDFfiHook

使用 `libffi` 实现 Objective-C 方法 Hook（支持实例方法、类方法、单实例 Hook）。

## 原理

`libffi` 会基于 `Method` 动态生成新的 `IMP`，并把这个 `IMP` 绑定到 C 回调。随后通过 runtime 把原方法实现替换为新 `IMP`。  
当方法被调用时，统一进入 C 回调，再按 `Before/Instead/After` 的顺序决定是否调用原始实现。

## 安装

```ruby
pod 'ZDFfiHook', :git => 'https://github.com/faimin/ZDFfiHook.git'
```

仓库依赖 `ZDLibffi`，`pod install` 时会自动安装。

## 快速开始

```objc
#import <ZDFfiHook/ZDFfiHook.h>
```

```objc
// 目标方法
- (id)exeA:(NSInteger)a b:(NSString *)b c:(id)c {
    return [NSString stringWithFormat:@"结果 = %zd，%@，%@", a, b, c];
}

- (void)setupHook {
    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:)
                               option:ZDHookOption_Before
                             callback:^(NSInteger a, NSString *b, id c) {
        NSLog(@"before: %zd, %@, %@", a, b, c);
    }];

    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:)
                               option:ZDHookOption_After
                             callback:^(NSInteger a, NSString *b, id c) {
        NSLog(@"after");
    }];
}
```

## API

```objc
/// Hook 实例方法（作用于整个类）
+ (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

/// Hook 类方法
+ (ZDFfiHookInfo *)zd_hookClassMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

/// 只 Hook 单个实例对象
- (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

/// 移除 Hook（传入 Hook 返回的 token）
+ (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token;

/// 单实例 Hook 的 token（通常可不手动移除，对象释放时会自动移除）
- (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token;
```

## Hook 选项

- `ZDHookOption_Before`：先执行 callback，再执行原方法。
- `ZDHookOption_After`：先执行原方法，再执行 callback。
- `ZDHookOption_Instead`：只执行 callback，不执行原方法。

## 回调签名规则（重点）

- callback 参数必须和被 Hook 方法参数一一对应，但不包含 `self` 和 `_cmd`。
- 无参方法 callback 写成 `^{ ... }`。
- callback 返回值会被忽略，建议统一写 `void`。
- 参数类型不匹配会导致断言或崩溃。

## 常见场景

### 1) Hook 类的实例方法

```objc
[UIViewController zd_hookInstanceMethod:@selector(viewDidLoad)
                                 option:ZDHookOption_After
                               callback:^{
    NSLog(@"any viewDidLoad hooked");
}];
```

### 2) Hook 类方法

```objc
[MyManager zd_hookClassMethod:@selector(sharedInstance)
                       option:ZDHookOption_Before
                     callback:^{
    NSLog(@"sharedInstance will call");
}];
```

### 3) 只 Hook 某个对象实例

```objc
ZDFfiHookInfo *token = [self.someController zd_hookInstanceMethod:@selector(viewWillAppear:)
                                                           option:ZDHookOption_After
                                                         callback:^(BOOL animated) {
    NSLog(@"only this instance hooked: %d", animated);
}];

// 可选：手动移除
[self.someController zd_removeHookToken:token];
```

## 注意事项

- 复杂结构体参数/返回值暂不建议使用（当前 `ffi_type` 映射主要覆盖对象、指针、SEL 和基础数值类型）。
- `ZDHookOption_Instead` 适合 `void` 方法；对有返回值的方法使用 `Instead` 需自行评估风险。
- 单实例 Hook 会动态创建子类（类似 KVO 的做法）以保证仅影响当前对象。

## 运行 Demo

```bash
pod install
open ZDFfiHookDemo.xcworkspace
```

选择 `ZDFfiHookDemo` scheme 运行即可。

## 参考

- [libffi 基本用法](https://github.com/faimin/ZDLibffiDemo)
