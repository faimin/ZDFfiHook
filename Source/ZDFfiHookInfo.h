//
//  ZDFfiHookInfo.h
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <ZDLibffi/ffi.h>
#import "ZDFfiDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZDFfiHookInfo<__covariant T> : NSObject {
    @public
    ffi_cif *_cif;
    ffi_type **_argTypes;
    ffi_closure *_closure;

    void *_originalIMP;
    void *_newIMP;
}
@property (nonatomic, readonly) Method method;
@property (nonatomic, readonly) const char *typeEncoding;
@property (nonatomic, weak, readonly) id obj;
@property (nonatomic, strong, readonly) NSMethodSignature *signature;
@property (nonatomic, assign, readonly) BOOL isBlock;

@property (nonatomic, copy) NSArray<T> *beforeCallbacks;
@property (nonatomic, copy) NSArray<T> *insteadCallbacks;
@property (nonatomic, copy) NSArray<T> *afterCallbacks;

// callback专属属性
@property (nonatomic, strong, readonly) id callback;
@property (nonatomic, assign, readonly) ZDHookOption option;


// 处理正常对象的
+ (instancetype)infoWithObject:(id)obj method:(Method _Nullable)method;
// 解析callBack回调的
+ (instancetype)infoWithCallback:(id)callback
                          option:(ZDHookOption)option
                          method:(Method)method;

// 增删callbackModel
- (void)addHookInfo:(T)callbackInfo;
- (BOOL)removeHookInfo:(T)callbackInfo;

@end

NS_ASSUME_NONNULL_END
