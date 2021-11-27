//
//  NSObject+ZDFfiHook.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import "NSObject+ZDFfiHook.h"
#import <objc/runtime.h>
#import "ZDFfiHookCore.h"

@interface ZD_AVOID_ALL_LOAD_FLAG_FOR_CATEGORY_NSObject_ZDFfiHook : NSObject @end
@implementation ZD_AVOID_ALL_LOAD_FLAG_FOR_CATEGORY_NSObject_ZDFfiHook @end

@implementation NSObject (ZDFfiHook)

+ (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback {
    Method method = class_getInstanceMethod(self, selector);
    return ZD_CoreHookFunc(self, method, option, callback);
}

+ (ZDFfiHookInfo *)zd_hookClassMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback {
    Class realClass = object_getClass(self);
    Method method = class_getClassMethod(realClass, selector);
    return ZD_CoreHookFunc(realClass, method, option, callback);
}

- (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback {
    Method method = class_getInstanceMethod(self.class, selector);
    return ZD_CoreHookFunc(self, method, option, callback);
}

+ (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token {
    return ZD_RemoveHookTokenFunc(self, token);
}

- (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token {
    return ZD_RemoveHookTokenFunc(self, token);
}

@end
