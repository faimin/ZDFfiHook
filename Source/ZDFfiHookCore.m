//
//  ZDFfiHookCore.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import "ZDFfiHookCore.h"
#import <objc/message.h>
#import "ZDFfiDefine.h"
#import "ZDFfiFunctions.h"
#import "NSObject+ZDAutoFree.h"

static NSString *const ZD_FFI_SubclassPrefix = @"ZD_AOP_";
static NSString *const ZD_KVO_SubclassPrefix = @"NSKVONotifying_";
//static NSString *const ZD_Aspect_SubclassSuffix = @"_Aspects_";

static void *ZD_SubclassAssociationKey = &ZD_SubclassAssociationKey;

@interface NSInvocation (ZDFFiPrivateAPI)
- (void)invokeUsingIMP:(IMP)imp;
@end

// 生成关联的key
static const SEL ZD_AssociatedKey(SEL selector) {
    NSCAssert(selector != NULL, @"selector不能为NULL");
    NSString *selectorString = [ZD_FFI_SubclassPrefix stringByAppendingString:NSStringFromSelector(selector)];
    SEL keySelector = NSSelectorFromString(selectorString);
    return keySelector;
}

static void ZD_SwizzleGetClass(Class class, Class statedClass) {
    SEL selector = @selector(class);
    Method method = class_getInstanceMethod(class, selector);
    IMP newIMP = imp_implementationWithBlock(^Class(id self) {
        return statedClass;
    });
    class_replaceMethod(class, selector, newIMP, method_getTypeEncoding(method));
}

// refer from `NSObject+RACSelectorSignal`
static Class ZD_CreateDynamicSubClass(id self) {
    Class knownDynamicSubclass = objc_getAssociatedObject(self, ZD_SubclassAssociationKey);
    if (knownDynamicSubclass != Nil) {
        return knownDynamicSubclass;
    }
    
    Class statedClass = [self class];
    Class baseClass = object_getClass(self);
    
    //NSString *baseClassName = NSStringFromClass(baseClass);
    //if ([baseClassName hasPrefix:ZD_KVO_SubclassPrefix]) {
    if (baseClass != statedClass) {
        objc_setAssociatedObject(self, ZD_SubclassAssociationKey, baseClass, OBJC_ASSOCIATION_ASSIGN);
        return baseClass;
    }
    
    const char *subClassName = [ZD_FFI_SubclassPrefix stringByAppendingString:NSStringFromClass(baseClass)].UTF8String;
    Class subClass = objc_getClass(subClassName);
    if (!subClass) {
        subClass = objc_allocateClassPair(baseClass, subClassName, 0);
        {
            ZD_SwizzleGetClass(subClass, statedClass);
        }
        objc_registerClassPair(subClass);
    }
    object_setClass(self, subClass);
    objc_setAssociatedObject(self, ZD_SubclassAssociationKey, subClass, OBJC_ASSOCIATION_ASSIGN);
    
    return subClass;
}

static Class ZD_CreateDynamicSubClassIfNeed(id self, Method *method, BOOL *hookedInstance) {
    NSCAssert(self && method, @"can't be nil");
    
    BOOL isInstance = !object_isClass(self);
    if (hookedInstance) {
        *hookedInstance = isInstance;
    }
    if (!isInstance) {
        return self;
    }
    
    // only instance hook need kvo's operation which create subclass dynamiced
    Class aSubClass = ZD_CreateDynamicSubClass(self);
    Method tempMethod = *method;
    SEL aSelector = method_getName(tempMethod);
    
    if (method) {
        *method = class_getInstanceMethod(aSubClass, aSelector);
    }
    return aSubClass;
}

#pragma mark - Signature Validation

static NSString *ZD_NormalizedTypeEncoding(const char *typeEncoding) {
    if (!typeEncoding) {
        return nil;
    }
    
    const char *normalizedType = typeEncoding;
    while (*normalizedType == 'r' || *normalizedType == 'n' || *normalizedType == 'N' ||
           *normalizedType == 'o' || *normalizedType == 'O' || *normalizedType == 'R' ||
           *normalizedType == 'V') {
        normalizedType++;
    }
    
    if (*normalizedType == '\0') {
        return nil;
    }
    return ZDFfi_ReduceBlockSignatureCodingType(normalizedType);
}

#if DEBUG
FOUNDATION_EXPORT NSString *ZD_TestOnlyNormalizedTypeEncoding(const char *typeEncoding) {
    return ZD_NormalizedTypeEncoding(typeEncoding);
}
#endif

static NSString *ZD_NormalizedMethodSignatureEncoding(NSMethodSignature *signature) {
    if (!signature) {
        return nil;
    }
    
    NSMutableString *encoding = [NSMutableString string];
    NSString *returnType = ZD_NormalizedTypeEncoding(signature.methodReturnType);
    if (returnType.length > 0) {
        [encoding appendString:returnType];
    }
    
    for (NSUInteger i = 0; i < signature.numberOfArguments; ++i) {
        NSString *argType = ZD_NormalizedTypeEncoding([signature getArgumentTypeAtIndex:i]);
        if (argType.length > 0) {
            [encoding appendString:argType];
        }
    }
    return encoding.copy;
}

static NSString *ZD_ExpectedCallbackEncoding(NSMethodSignature *methodSignature) {
    if (!methodSignature) {
        return nil;
    }
    
    NSMutableString *encoding = [NSMutableString stringWithString:@"v@?"];
    for (NSUInteger i = 2; i < methodSignature.numberOfArguments; ++i) {
        NSString *argType = ZD_NormalizedTypeEncoding([methodSignature getArgumentTypeAtIndex:i]);
        if (argType.length > 0) {
            [encoding appendString:argType];
        }
    }
    return encoding.copy;
}

static BOOL ZD_ValidateCallbackSignatureForFFICall(NSMethodSignature *methodSignature,
                                                   NSMethodSignature *callbackSignature,
                                                   NSString * _Nullable * _Nullable expectedEncodingOut,
                                                   NSString * _Nullable * _Nullable actualEncodingOut,
                                                   NSString * _Nullable * _Nullable reasonOut) {
    NSString *expectedEncoding = ZD_ExpectedCallbackEncoding(methodSignature);
    NSString *actualEncoding = ZD_NormalizedMethodSignatureEncoding(callbackSignature);
    if (expectedEncodingOut) {
        *expectedEncodingOut = expectedEncoding;
    }
    if (actualEncodingOut) {
        *actualEncodingOut = actualEncoding;
    }
    
    if (!methodSignature || !callbackSignature) {
        if (reasonOut) {
            *reasonOut = @"无法解析方法签名或 callback 闭包签名。";
        }
        return NO;
    }
    
    NSString *callbackReturnType = ZD_NormalizedTypeEncoding(callbackSignature.methodReturnType);
    if (![callbackReturnType isEqualToString:@"v"]) {
        if (reasonOut) {
            *reasonOut = [NSString stringWithFormat:@"返回值不匹配：callback 必须返回 void(v)，实际返回 `%@`。", callbackReturnType ?: @"(null)"];
        }
        return NO;
    }
    
    NSUInteger expectedArgCount = methodSignature.numberOfArguments - 1; // block 的第 0 个参数是自己
    NSUInteger actualArgCount = callbackSignature.numberOfArguments;
    if (actualArgCount != expectedArgCount) {
        if (reasonOut) {
            *reasonOut = [NSString stringWithFormat:@"参数个数不匹配：期望 `%lu`，实际 `%lu`。",
                          (unsigned long)expectedArgCount,
                          (unsigned long)actualArgCount];
        }
        return NO;
    }
    
    NSString *callbackBlockSelfType = ZD_NormalizedTypeEncoding([callbackSignature getArgumentTypeAtIndex:0]);
    if (![callbackBlockSelfType isEqualToString:@"@?"]) {
        if (reasonOut) {
            *reasonOut = [NSString stringWithFormat:@"callback 第 0 个参数必须是 block 自身(@?)，实际为 `%@`。", callbackBlockSelfType ?: @"(null)"];
        }
        return NO;
    }
    
    for (NSUInteger callbackArgIndex = 1; callbackArgIndex < actualArgCount; ++callbackArgIndex) {
        NSUInteger methodArgIndex = callbackArgIndex + 1;
        NSString *expectedArgType = ZD_NormalizedTypeEncoding([methodSignature getArgumentTypeAtIndex:methodArgIndex]);
        NSString *actualArgType = ZD_NormalizedTypeEncoding([callbackSignature getArgumentTypeAtIndex:callbackArgIndex]);
        if (![expectedArgType isEqualToString:actualArgType]) {
            if (reasonOut) {
                *reasonOut = [NSString stringWithFormat:@"参数类型不匹配：callback 第 `%lu` 个参数应为 `%@`（对应被 hook 方法第 `%lu` 个参数），实际为 `%@`。",
                              (unsigned long)callbackArgIndex,
                              expectedArgType ?: @"(null)",
                              (unsigned long)methodArgIndex,
                              actualArgType ?: @"(null)"];
            }
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Core Func

// 转发的IMP函数
static void ZD_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *userdata) {
    ZDFfiHookInfo *info = (__bridge ZDFfiHookInfo *)userdata;
    
    NSMethodSignature *methodSignature = info.signature;
    
#if DEBUG
    const char *mapedTypeEncoding = ZDFfi_ReduceBlockSignatureCodingType(info.typeEncoding).UTF8String;
    NSUInteger argCount = 0;
    for (NSInteger i = 0; mapedTypeEncoding[i] != '\0'; ++i) {
        if (mapedTypeEncoding[i] == ':') {
            ++argCount;
        }
    }
    printf("参数个数：-------- %zd\n", argCount);
    printf("精简后的方法签名：%s\n", mapedTypeEncoding);
    
    // 打印参数
    NSUInteger beginIndex = 2;
    if (info.isBlock) {
        beginIndex = 1;
    }
    for (NSUInteger i = beginIndex; i < methodSignature.numberOfArguments; ++i) {
        id argValue = ZDFfi_ArgumentAtIndex(methodSignature, args, i);
        NSLog(@"arg ==> index: %zd, value: %@", i, argValue);
    }
#endif
    
    __auto_type callBlock = ^(ZDFfiHookInfo *callbackInfo){
        // block没有SEL,所以比普通方法少一个参数
        void **callbackArgs = calloc(methodSignature.numberOfArguments - 1, sizeof(void *));
        id block = callbackInfo.callback;
        callbackArgs[0] = (void *)&block;
        // 从index=2位置开始把args中的数据拷贝到callbackArgs中(从index=1开始，第0个位置留给block自己)
        memcpy(callbackArgs + 1, args + 2, sizeof(*args)*(methodSignature.numberOfArguments - 2));
        /*
        for (NSInteger i = 2; i < methodSignature.numberOfArguments; ++i) {
            callbackArgs[i - 1] = args[i];
        }
         */
        NSString *expectedEncoding = nil;
        NSString *actualEncoding = nil;
        NSString *reason = nil;
        BOOL valid = ZD_ValidateCallbackSignatureForFFICall(methodSignature, callbackInfo.signature, &expectedEncoding, &actualEncoding, &reason);
        if (!valid) {
            NSString *selectorName = callbackInfo.method ? NSStringFromSelector(method_getName(callbackInfo.method)) : @"(unknown)";
            NSCAssert(NO, @"[ZDFfiHook] callback signature mismatch before ffi_call.\nselector: %@\nexpected callback signature: %@\nactual callback signature: %@\nreason: %@\n要求: callback 必须是 `void (^...)(...)` 且参数类型与被 hook 方法(去除 self/_cmd)一致。", selectorName, expectedEncoding ?: @"(null)", actualEncoding ?: @"(null)", reason ?: @"(unknown)");
            free(callbackArgs);
            return;
        }

        IMP blockIMP = callbackInfo->_originalIMP;
        // 根据 cif模版，函数指针，返回值指针，函数参数 调用这个函数
        ffi_call(callbackInfo->_cif, FFI_FN(blockIMP), NULL, callbackArgs);
        free(callbackArgs);
    };
    
    // before
    if (info.beforeCallbacks.count > 0) {
        for (ZDFfiHookInfo *callbackInfo in info.beforeCallbacks) {
            callBlock(callbackInfo);
        }
    }
    
    // instead
    if (info.insteadCallbacks) {
        for (ZDFfiHookInfo *callbackInfo in info.insteadCallbacks) {
            callBlock(callbackInfo);
        }
    }
    else {
        BOOL isMsgForward = FFI_FN(info->_originalIMP) == _objc_msgForward
    #if !defined(__arm64__)
        || FFI_FN(info->_originalIMP) == _objc_msgForward_stret
    #endif
        ;
        // 参考stinger的思路
        if (isMsgForward) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            for (NSInteger i = 0; i < methodSignature.numberOfArguments; ++i) {
                [invocation setArgument:args[i] atIndex:i];
            }
            if ([invocation respondsToSelector:@selector(invokeUsingIMP:)]) {
                [invocation invokeUsingIMP:info->_originalIMP];
            }
            else {
                NSCAssert(NO, @"invokeUsingIMP: 私有方法失效了");
            }
            if (ret && methodSignature.methodReturnLength > 0) {
                [invocation getReturnValue:ret];
            }
        }
        else {
            ffi_call(cif, FFI_FN(info->_originalIMP), ret, args);
        }
    }
    
    // after
    if (info.afterCallbacks) {
        for (ZDFfiHookInfo *callbackInfo in info.afterCallbacks) {
            callBlock(callbackInfo);
        }
    }
}

#pragma mark - Public

ZDFfiHookInfo *ZD_CoreHookFunc(id self, Method method, ZDHookOption option, id callback) {
    if (!self || !method) {
        NSCAssert(NO, @"参数错误");
        return nil;
    }
    
    //如果self是实例，则认为hook的是单个实例变量，此时会动态创建subclass进行hook
    BOOL hookedInstance = NO;
    id willBeHookedClass = ZD_CreateDynamicSubClassIfNeed(self, &method, &hookedInstance);
    
    const SEL key = ZD_AssociatedKey(method_getName(method));
    ZDFfiHookInfo *hookInfo = objc_getAssociatedObject(willBeHookedClass, key);
    if (!hookInfo) {
        hookInfo = [ZDFfiHookInfo infoWithObject:willBeHookedClass method:method];
        // info需要被强引用，否则会出现内存crash
        objc_setAssociatedObject(willBeHookedClass, key, hookInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 构造参数类型列表
        const unsigned int argsCount = method_getNumberOfArguments(method);
        ffi_type **argTypes = calloc(argsCount, sizeof(ffi_type *));
        for (int i = 0; i < argsCount; ++i) {
            const char *argType = [hookInfo.signature getArgumentTypeAtIndex:i];
            if (hookInfo.isBlock) {
                argType = ZDFfi_ReduceBlockSignatureCodingType(argType).UTF8String;
            }
            ffi_type *arg_ffi_type = ZDFfi_ffiTypeFromTypeEncoding(argType);
            NSCAssert(arg_ffi_type, @"can't find a ffi_type ==> %s", argType);
            argTypes[i] = arg_ffi_type;
        }
        // 返回值类型
        ffi_type *retType = ZDFfi_ffiTypeFromTypeEncoding(hookInfo.signature.methodReturnType);
        
        //需要在堆上开辟内存，否则会出现内存问题(ffi_cif *会在ZDFfiHookInfo释放时会free掉)
        ffi_cif *cif = calloc(1, sizeof(ffi_cif));
        //生成ffi_cfi模版对象，保存函数参数个数、类型等信息
        ffi_status prepCifStatus = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argsCount, retType, argTypes);
        if (prepCifStatus != FFI_OK) {
            NSCAssert1(NO, @"ffi_prep_cif failed = %d", prepCifStatus);
            return nil;
        }
        
        // 生成新的IMP
        void *newIMP = NULL;
        ffi_closure *cloure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&newIMP);
        {
            hookInfo->_cif = cif;
            hookInfo->_argTypes = argTypes;
            hookInfo->_closure = cloure;
            hookInfo->_newIMP = newIMP;
        };
        ffi_status prepClosureStatus = ffi_prep_closure_loc(cloure, cif, ZD_ffi_closure_func, (__bridge void *)hookInfo, newIMP);
        if (prepClosureStatus != FFI_OK) {
            NSCAssert1(NO, @"ffi_prep_closure_loc failed = %d", prepClosureStatus);
            return nil;
        }

        //替换IMP实现
        Class hookClass = willBeHookedClass;
        SEL aSelector = method_getName(method);
        const char *typeEncoding = method_getTypeEncoding(method);
        // add method，or else replace the exists method's imp
        if (!class_addMethod(hookClass, aSelector, newIMP, typeEncoding)) {
            /*
            if ([NSStringFromClass(hookClass) hasPrefix:ZD_KVO_SubclassPrefix]) {
                NSCAssert(NO, @"暂不支持hook被KVO过的属性方法，请先hook再KVO");
                return nil;
            }
            */
            //IMP originIMP = class_replaceMethod(hookClass, aSelector, newIMP, typeEncoding);
            IMP originIMP = method_setImplementation(method, newIMP);
            if (hookInfo->_originalIMP != originIMP) {
                hookInfo->_originalIMP = originIMP;
            }
        }
    }
    
    if (!callback) {
        return nil;
    }
    
    ZDFfiHookInfo *callbackInfo = [ZDFfiHookInfo infoWithCallback:callback option:option method:method];
    // 组装callback block
    const unsigned int argsCount = method_getNumberOfArguments(method);
    uint blockArgsCount = argsCount - 1;
    ffi_type **blockArgTypes = calloc(blockArgsCount, sizeof(ffi_type *));
    blockArgTypes[0] = &ffi_type_pointer; //第一个参数是block自己，肯定为指针类型
    for (int i = 2; i < argsCount; ++i) {
        blockArgTypes[i-1] = ZDFfi_ffiTypeFromTypeEncoding([hookInfo.signature getArgumentTypeAtIndex:i]);
    }
    callbackInfo->_argTypes = blockArgTypes;
    
    ffi_cif *callbackCif = calloc(1, sizeof(ffi_cif));
    if (ffi_prep_cif(callbackCif, FFI_DEFAULT_ABI, blockArgsCount, &ffi_type_void, blockArgTypes) == FFI_OK) {
        callbackInfo->_cif = callbackCif;
        
        [hookInfo addHookInfo:callbackInfo];
        
        // hook实例对象时，在实例释放时移除callBack
        if (hookedInstance) {
            __weak typeof(hookInfo) weakHookInfo = hookInfo;
            __weak typeof(callbackInfo) weakCallbackInfo = callbackInfo;
            [self zdAutoFree_deallocBlock:^(id  _Nonnull unsafeSelf) {
                __strong typeof(weakHookInfo) hookInfo = weakHookInfo;
                __strong typeof(weakCallbackInfo) callbackInfo = weakCallbackInfo;
                [hookInfo removeHookInfo:callbackInfo];
            }];
        }
    }
    else {
        NSCAssert(NO, @"💔");
        return nil;
    }
    
    return callbackInfo;
}

BOOL ZD_RemoveHookTokenFunc(id self, ZDFfiHookInfo *token) {
    if (!self || !token) {
        return NO;
    }
    Class knownDynamicSubclass = objc_getAssociatedObject(self, ZD_SubclassAssociationKey);
    if (knownDynamicSubclass) {
        self = knownDynamicSubclass;
    }
    const SEL key = ZD_AssociatedKey(method_getName(token.method));;
    ZDFfiHookInfo *hookInfo = objc_getAssociatedObject(self, key);
    if (!hookInfo) {
        return NO;
    }
    
    BOOL ret = [hookInfo removeHookInfo:token];
    return ret;
}
